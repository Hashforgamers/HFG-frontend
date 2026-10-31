"""Local stand-in for the Hash Medusa store API (HFG-STORE-API.md).

Dev only: in-memory, any non-empty HFG token is accepted, no real payments.

    python3 tool/mock_medusa/server.py            # listens on 0.0.0.0:9000

Run the app with
    --dart-define=MEDUSA_BASE_URL=http://<mac-ip>:9000
(the app reads the publishable key and region from /hash-store/config)
"""

import base64
import json
import random
import re
import time
import uuid
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

PUBLISHABLE_KEY = "pk_local_mock"
REGION = {
    "id": "reg_local_in",
    "name": "India",
    "currency_code": "inr",
    "countries": [{"iso_2": "in", "display_name": "India"}],
}

PRODUCTS = [
    ("hv_arena", "Hash Arena", "PS5 session - 1 hour", "Book a console bay at the arena.", "service", 400, 12, "ps5"),
    ("hv_arena", "Hash Arena", "PC gaming - 2 hours", "RTX rig, 240 Hz monitor, any game.", "service", 600, 8, "gaming-pc"),
    ("hv_arena", "Hash Arena", "VR experience", "30 minutes in the VR pod.", "service", 350, 0, "vr"),
    ("hv_gear", "Hash Gear", "Hash pro mouse pad", "XL cloth pad with stitched edges.", "product", 799, 25, "mousepad"),
    ("hv_gear", "Hash Gear", "Hash hoodie", "Heavyweight black hoodie, neon print.", "product", 1999, 10, "hoodie"),
    ("hv_gear", "Hash Gear", "Energy drink 4-pack", "Fuel for the late-night grind.", "product", 499, 40, "energy-drink"),
]
CATALOG = [
    {
        "product_id": f"prod_{i}",
        "vendor_id": v,
        "vendor_name": vn,
        "title": t,
        "description": d,
        "kind": k,
        "variant_id": f"variant_{i}",
        "price_inr": p,
        "available": a,
        "thumbnail": f"https://picsum.photos/seed/hash-{seed}/600/600",
    }
    for i, (v, vn, t, d, k, p, a, seed) in enumerate(PRODUCTS, 1)
]
BY_VARIANT = {p["variant_id"]: p for p in CATALOG}
SHIPPING = [
    {"id": "so_standard", "name": "Standard delivery (demo)", "amount": 0},
    {"id": "so_express", "name": "Express delivery (demo)", "amount": 49},
]

customers = {}  # hfg identity -> customer
carts = {}
collections = {}
orders = {}
hash_orders = {}  # order id -> {paid, completed_at, completion_eligible, otp_at}


def now():
    return datetime.now(timezone.utc).isoformat()


def jwt(actor_id):
    def part(o):
        return base64.urlsafe_b64encode(json.dumps(o).encode()).decode().rstrip("=")

    return f"{part({'alg': 'none'})}.{part({'actor_id': actor_id, 'actor_type': 'customer'})}.mock"


def actor_of(auth_header):
    try:
        payload = auth_header.split(" ", 1)[1].split(".")[1]
        payload += "=" * (-len(payload) % 4)
        return json.loads(base64.urlsafe_b64decode(payload))["actor_id"]
    except Exception:
        return None


def totals(cart):
    for item in cart["items"]:
        item["total"] = item["unit_price"] * item["quantity"]
        item["subtotal"] = item["total"]
    sub = sum(i["total"] for i in cart["items"])
    ship = sum(m["amount"] for m in cart["shipping_methods"])
    cart.update(
        subtotal=sub, item_subtotal=sub, shipping_total=ship, tax_total=0, discount_total=0, total=sub + ship
    )
    return cart


class ApiError(Exception):
    def __init__(self, status, message):
        self.status, self.message = status, message


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print(f"{self.command} {self.path} -> {args[1] if len(args) > 1 else ''}")

    def send(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def body(self):
        n = int(self.headers.get("Content-Length") or 0)
        return json.loads(self.rfile.read(n) or b"{}") if n else {}

    def customer(self):
        actor = actor_of(self.headers.get("Authorization", ""))
        cust = next((c for c in customers.values() if c["id"] == actor), None)
        if not cust:
            raise ApiError(401, "Unauthorized")
        return cust

    def handle_any(self):
        url = urlparse(self.path)
        path, q = url.path.rstrip("/"), {k: v[0] for k, v in parse_qs(url.query).items()}
        try:
            if path.startswith("/store") and self.headers.get("x-publishable-api-key") != PUBLISHABLE_KEY:
                raise ApiError(400, "A valid publishable key is required")
            for method, pattern, fn in ROUTES:
                m = re.fullmatch(pattern, path)
                if m and method == self.command:
                    status, body = fn(self, q, *m.groups())
                    return self.send(status, body)
            raise ApiError(404, f"Cannot {self.command} {path}")
        except ApiError as e:
            self.send(e.status, {"type": "invalid_data", "message": e.message})

    do_GET = do_POST = do_DELETE = handle_any


def route(method, pattern):
    def deco(fn):
        ROUTES.append((method, pattern, fn))
        return fn

    return deco


ROUTES = []


@route("GET", r"/hash-store/config")
def store_config(h, q):
    return 200, {
        "version": 1,
        "publishable_api_key": PUBLISHABLE_KEY,
        "region_id": REGION["id"],
        "sales_channel_id": "sc_local",
        "currency_code": "inr",
        "country_code": "in",
    }


@route("POST", r"/auth/customer/hfg")
def auth_hfg(h, q):
    token = h.body().get("token") or ""
    if not token:
        raise ApiError(401, "Invalid HFG session")
    # shortcut: one local identity for every HFG token, real bridge maps hfg:<id>.
    cust = customers.get("hfg:local")
    return 200, {"token": jwt(cust["id"] if cust else "")}


@route("POST", r"/store/customers")
def create_customer(h, q):
    b = h.body()
    if "hfg:local" in customers:
        raise ApiError(400, "Identity already has a customer")
    customers["hfg:local"] = {
        "id": f"cus_{uuid.uuid4().hex[:10]}",
        "first_name": b.get("first_name"),
        "email": b.get("email"),
        "phone": b.get("phone"),
        "addresses": [],
    }
    return 200, {"customer": customers["hfg:local"]}


@route("GET", r"/store/customers/me")
def me(h, q):
    return 200, {"customer": h.customer()}


@route("GET", r"/store/customers/me/addresses")
def addresses(h, q):
    a = h.customer()["addresses"]
    return 200, {"addresses": a, "count": len(a), "offset": 0, "limit": 50}


@route("GET", r"/store/regions")
def regions(h, q):
    return 200, {"regions": [REGION], "count": 1, "offset": 0, "limit": 50}


@route("GET", r"/store/hash/products")
def catalog(h, q):
    rows = [p for p in CATALOG if not q.get("vendor_id") or p["vendor_id"] == q["vendor_id"]]
    off, lim = int(q.get("offset", 0)), int(q.get("limit", 20))
    return 200, {"products": rows[off : off + lim], "count": len(rows), "offset": off, "limit": lim, "currency_code": "inr"}


def get_cart(h, cart_id):
    h.customer()
    cart = carts.get(cart_id)
    if not cart:
        raise ApiError(404, f"Cart id {cart_id} not found")
    return cart


def add_line(cart, variant_id, qty):
    p = BY_VARIANT.get(variant_id)
    if not p or p["available"] <= 0:
        raise ApiError(400, "This listing is unavailable")
    if cart["items"] and cart["vendor_id"] != p["vendor_id"]:
        raise ApiError(400, "A cart can only contain one vendor's items")
    cart["vendor_id"] = p["vendor_id"]
    existing = next((i for i in cart["items"] if i["variant_id"] == variant_id), None)
    if existing:
        existing["quantity"] += qty
    else:
        cart["items"].append(
            {
                "id": f"item_{uuid.uuid4().hex[:10]}",
                "variant_id": variant_id,
                "title": p["title"],
                "product_title": p["title"],
                "variant_title": "Default variant",
                "thumbnail": p["thumbnail"],
                "quantity": qty,
                "unit_price": p["price_inr"],
            }
        )


@route("POST", r"/store/carts")
def create_cart(h, q):
    cust, b = h.customer(), h.body()
    cart = {
        "id": f"cart_{uuid.uuid4().hex[:10]}",
        "region_id": b.get("region_id"),
        "currency_code": "inr",
        "email": b.get("email") or cust.get("email"),
        "customer_id": cust["id"],
        "items": [],
        "shipping_methods": [],
        "shipping_address": b.get("shipping_address"),
        "payment_collection": None,
        "completed_at": None,
        "vendor_id": None,
    }
    for item in b.get("items", []):
        add_line(cart, item["variant_id"], int(item.get("quantity", 1)))
    carts[cart["id"]] = cart
    return 200, {"cart": totals(cart)}


@route("GET", r"/store/carts/([\w-]+)")
def read_cart(h, q, cid):
    return 200, {"cart": totals(get_cart(h, cid))}


@route("POST", r"/store/carts/([\w-]+)")
def update_cart(h, q, cid):
    cart, b = get_cart(h, cid), h.body()
    for k in ("email", "shipping_address", "billing_address"):
        if k in b:
            cart[k] = b[k]
    return 200, {"cart": totals(cart)}


@route("POST", r"/store/carts/([\w-]+)/line-items")
def add_item(h, q, cid):
    cart, b = get_cart(h, cid), h.body()
    add_line(cart, b["variant_id"], int(b.get("quantity", 1)))
    return 200, {"cart": totals(cart)}


@route("POST", r"/store/carts/([\w-]+)/line-items/([\w-]+)")
def set_qty(h, q, cid, iid):
    cart = get_cart(h, cid)
    item = next((i for i in cart["items"] if i["id"] == iid), None)
    if not item:
        raise ApiError(404, "Line item not found")
    item["quantity"] = int(h.body()["quantity"])
    return 200, {"cart": totals(cart)}


@route("DELETE", r"/store/carts/([\w-]+)/line-items/([\w-]+)")
def remove_item(h, q, cid, iid):
    cart = get_cart(h, cid)
    cart["items"] = [i for i in cart["items"] if i["id"] != iid]
    return 200, {"id": iid, "object": "line-item", "deleted": True, "parent": totals(cart)}


@route("GET", r"/store/shipping-options")
def shipping_options(h, q):
    get_cart(h, q.get("cart_id", ""))
    return 200, {"shipping_options": SHIPPING}


@route("POST", r"/store/carts/([\w-]+)/shipping-methods")
def select_shipping(h, q, cid):
    cart, option_id = get_cart(h, cid), h.body().get("option_id")
    opt = next((o for o in SHIPPING if o["id"] == option_id), None)
    if not opt:
        raise ApiError(400, "Shipping option not found")
    cart["shipping_methods"] = [{"id": f"sm_{opt['id']}", "shipping_option_id": opt["id"], "name": opt["name"], "amount": opt["amount"]}]
    return 200, {"cart": totals(cart)}


@route("GET", r"/store/payment-providers")
def providers(h, q):
    h.customer()
    return 200, {"payment_providers": [{"id": "pp_system_default", "is_enabled": True}]}


@route("POST", r"/store/payment-collections")
def create_collection(h, q):
    cart = get_cart(h, h.body().get("cart_id", ""))
    if cart["payment_collection"]:
        return 200, {"payment_collection": cart["payment_collection"]}
    pc = {"id": f"pay_col_{uuid.uuid4().hex[:10]}", "amount": totals(cart)["total"], "payment_sessions": []}
    collections[pc["id"]] = (pc, cart["id"])
    cart["payment_collection"] = pc
    return 200, {"payment_collection": pc}


@route("POST", r"/store/payment-collections/([\w-]+)/payment-sessions")
def payment_session(h, q, pcid):
    h.customer()
    if pcid not in collections:
        raise ApiError(404, "Payment collection not found")
    pc, _ = collections[pcid]
    pc["payment_sessions"] = [{"id": f"payses_{uuid.uuid4().hex[:8]}", "provider_id": h.body().get("provider_id"), "data": {}, "status": "pending"}]
    return 200, {"payment_collection": pc}


@route("POST", r"/store/carts/([\w-]+)/complete")
def complete(h, q, cid):
    cart = get_cart(h, cid)
    if not cart["items"]:
        raise ApiError(400, "Cart is empty")
    if not cart["shipping_methods"] or not cart.get("shipping_address") or not cart.get("email"):
        return 200, {"type": "cart", "cart": totals(cart), "error": {"message": "Add an email, address and delivery method first."}}
    if not (cart["payment_collection"] or {}).get("payment_sessions"):
        return 200, {"type": "cart", "cart": totals(cart), "error": {"message": "Payment is required to place this order."}}
    cart["completed_at"] = now()
    order = {
        "id": f"order_{uuid.uuid4().hex[:10]}",
        "display_id": len(orders) + 1001,
        "created_at": now(),
        "status": "pending",
        "payment_status": "authorized",
        "fulfillment_status": "not_fulfilled",
        "email": cart["email"],
        "currency_code": "inr",
        "customer_id": cart["customer_id"],
        "items": json.loads(json.dumps(cart["items"])),
        "shipping_address": cart["shipping_address"],
        "shipping_methods": cart["shipping_methods"],
        **{k: cart[k] for k in ("subtotal", "item_subtotal", "shipping_total", "tax_total", "discount_total", "total")},
    }
    orders[order["id"]] = order
    hash_orders[order["id"]] = {"paid": True, "completed_at": None, "completion_eligible": True, "otp_at": 0}
    addr = cart["shipping_address"]
    cust = h.customer()
    if addr and not any(a.get("address_1") == addr.get("address_1") for a in cust["addresses"]):
        cust["addresses"].append({"id": f"caddr_{uuid.uuid4().hex[:8]}", **addr})
    return 200, {"type": "order", "order": order}


def get_order(h, oid):
    cust = h.customer()
    order = orders.get(oid)
    if not order or order["customer_id"] != cust["id"]:
        raise ApiError(404, "Order not found")
    return order


@route("GET", r"/store/orders")
def list_orders(h, q):
    cust = h.customer()
    rows = sorted((o for o in orders.values() if o["customer_id"] == cust["id"]), key=lambda o: o["created_at"], reverse=True)
    off, lim = int(q.get("offset", 0)), int(q.get("limit", 20))
    return 200, {"orders": rows[off : off + lim], "count": len(rows), "offset": off, "limit": lim}


@route("GET", r"/store/orders/([\w-]+)")
def read_order(h, q, oid):
    return 200, {"order": get_order(h, oid)}


@route("GET", r"/store/hash/orders/([\w-]+)")
def hash_order(h, q, oid):
    get_order(h, oid)
    s = hash_orders[oid]
    return 200, {"order": {"id": oid, "paid": s["paid"], "completed_at": s["completed_at"], "completion_eligible": s["completion_eligible"]}}


@route("POST", r"/store/hash/orders/([\w-]+)/otp")
def otp(h, q, oid):
    get_order(h, oid)
    s = hash_orders[oid]
    if not s["completion_eligible"]:
        raise ApiError(400, "This order is not eligible for completion")
    wait = 60 - (time.time() - s["otp_at"])
    if wait > 0:
        raise ApiError(429, f"Please wait {int(wait)} seconds before requesting a new code.")
    s["otp_at"] = time.time()
    return 200, {
        "code": f"{random.randint(0, 999999):06d}",
        "expires_at": (datetime.now(timezone.utc) + timedelta(minutes=10)).isoformat(),
        "instruction": "Share this code with the partner only after successful delivery or service completion.",
    }


# Dev helper: mark an order completed as if the partner verified the code.
@route("POST", r"/dev/orders/([\w-]+)/complete")
def dev_complete(h, q, oid):
    if oid not in hash_orders:
        raise ApiError(404, "Order not found")
    hash_orders[oid].update(completed_at=now(), completion_eligible=False)
    orders[oid]["fulfillment_status"] = "delivered"
    return 200, {"ok": True}


if __name__ == "__main__":
    print("Mock Medusa on http://0.0.0.0:9000  (publishable key: pk_local_mock)")
    ThreadingHTTPServer(("0.0.0.0", 9000), Handler).serve_forever()
