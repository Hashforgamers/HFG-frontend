// Mirrors the app's DeepLinkService.parse / navigate (lib/core/service/deeplink_service.dart).
// Keep `opens` in sync when the app gains a screen for a destination.

export type DeepLinkParam = { key: string; label: string; placeholder: string };

export type DeepLinkDestination = {
  key: string;
  label: string;
  group: "Wallet" | "Shop" | "Games" | "Social" | "Inbox" | "Not routed yet";
  /** Path after `hash://`; `{name}` placeholders come from `params`. */
  path: string;
  params: DeepLinkParam[];
  /** False when the app parses the link but has no screen yet (lands on Home). */
  opens: boolean;
  hint: string;
};

const id = (key: string, label: string, placeholder: string) => ({ key, label, placeholder });

export const DESTINATIONS: DeepLinkDestination[] = [
  { key: "wallet", label: "Wallet", group: "Wallet", path: "wallet", params: [], opens: true, hint: "Hash coins balance, streak and rewards." },
  { key: "rewards", label: "Rewards", group: "Wallet", path: "rewards", params: [], opens: true, hint: "Rewards (shown inside the wallet)." },
  { key: "shop", label: "Shop home", group: "Shop", path: "shop", params: [], opens: true, hint: "Hash Store landing." },
  { key: "shop_cart", label: "Shop cart", group: "Shop", path: "shop/cart", params: [], opens: true, hint: "Abandoned-cart nudges." },
  { key: "shop_orders", label: "My orders", group: "Shop", path: "shop/orders", params: [], opens: true, hint: "Order list." },
  { key: "shop_product", label: "Product", group: "Shop", path: "shop/product/{product_id}", params: [id("product_id", "Product ID", "prod_123")], opens: true, hint: "A single product page." },
  { key: "shop_order", label: "Order detail", group: "Shop", path: "shop/order/{order_id}", params: [id("order_id", "Order ID", "ord_123")], opens: true, hint: "Order status / review." },
  { key: "ludo", label: "Ludo", group: "Games", path: "game/ludo", params: [], opens: true, hint: "Ludo lobby." },
  { key: "mini_games", label: "Mini-games leaderboard", group: "Games", path: "game/mini-games", params: [], opens: true, hint: "Arcade leaderboard + games." },
  { key: "ludo_quick_join", label: "Ludo quick-join", group: "Games", path: "game/ludojoin_{match_id}", params: [id("match_id", "Match ID", "abc123")], opens: true, hint: "Joins the room, or Quick Matches if it is gone." },
  { key: "ludo_match", label: "Ludo match", group: "Games", path: "game/ludomatch_{match_id}", params: [id("match_id", "Match ID", "abc123")], opens: true, hint: "A specific online Ludo match." },
  { key: "snl_match", label: "Snakes & Ladders match", group: "Games", path: "game/snlmatch_{match_id}", params: [id("match_id", "Match ID", "abc123")], opens: true, hint: "A specific S&L match." },
  { key: "wordly_match", label: "Wordly match", group: "Games", path: "game/wordlymatch_{match_id}", params: [id("match_id", "Match ID", "abc123")], opens: true, hint: "A specific Wordly match." },
  { key: "arrow_match", label: "Arrow Escape match", group: "Games", path: "game/arrowmatch_{match_id}", params: [id("match_id", "Match ID", "abc123")], opens: true, hint: "A specific Arrow Escape match." },
  { key: "bird_match", label: "Flappy match", group: "Games", path: "game/birdmatch_{match_id}", params: [id("match_id", "Match ID", "abc123")], opens: true, hint: "A specific Flappy Birds match." },
  { key: "team_join", label: "Team invite", group: "Social", path: "team/join?event_id={event_id}&team_id={team_id}", params: [id("event_id", "Event ID", "evt_1"), id("team_id", "Team ID", "team_1")], opens: true, hint: "Join a tournament team." },
  { key: "notifications", label: "Notifications inbox", group: "Inbox", path: "route:/notifications", params: [], opens: true, hint: "Sent as `route`, not a deep link." },
  { key: "chat", label: "Chat list", group: "Inbox", path: "route:/chat", params: [], opens: true, hint: "Sent as `route`, not a deep link." },
  { key: "tournament", label: "Tournament", group: "Not routed yet", path: "tournament/{tournament_id}", params: [id("tournament_id", "Tournament ID", "t_123")], opens: false, hint: "Tournaments are behind a feature flag (off)." },
  { key: "cafe", label: "Cafe", group: "Not routed yet", path: "cafe/{cafe_id}", params: [id("cafe_id", "Cafe ID", "cafe_1")], opens: false, hint: "No cafe screen yet." },
  { key: "bookings", label: "Booking", group: "Not routed yet", path: "bookings/{booking_id}", params: [id("booking_id", "Booking ID", "bk_1")], opens: false, hint: "No booking deep-link screen yet." },
  { key: "passes", label: "Passes", group: "Not routed yet", path: "passes", params: [], opens: false, hint: "No passes screen yet." },
  { key: "offer", label: "Offer", group: "Not routed yet", path: "offer", params: [], opens: false, hint: "No offer screen yet." },
  { key: "referral", label: "Referral", group: "Not routed yet", path: "referral/{code}", params: [id("code", "Referral code", "ZEYAN10")], opens: false, hint: "Attribution only; lands on Home." },
];

export const WEB_HOST = "https://www.hashforgamers.com";

export type Utm = { source?: string; medium?: string; campaign?: string; content?: string };

export type BuiltLink = {
  /** What goes into the push payload: `deep_link` or `route`. */
  kind: "deep_link" | "route";
  value: string;
  /** Shareable https App Link (null for routes). */
  web: string | null;
};

export function buildLink(dest: DeepLinkDestination, values: Record<string, string>, utm: Utm = {}): BuiltLink {
  if (dest.path.startsWith("route:")) {
    return { kind: "route", value: dest.path.slice("route:".length), web: null };
  }
  const path = dest.path.replace(/\{(\w+)\}/g, (_, k: string) => encodeURIComponent((values[k] ?? "").trim()));
  const [base, query = ""] = path.split("?");
  const params = new URLSearchParams(query);
  // The app's GrowthContext reads utm_* for attribution.
  for (const [k, v] of Object.entries(utm)) if (v?.trim()) params.set(`utm_${k}`, v.trim());
  const qs = params.toString();
  const suffix = `${base}${qs ? `?${qs}` : ""}`;
  return { kind: "deep_link", value: `hash://${suffix}`, web: `${WEB_HOST}/${suffix}` };
}

export function missingParams(dest: DeepLinkDestination, values: Record<string, string>) {
  return dest.params.filter((p) => !(values[p.key] ?? "").trim()).map((p) => p.label);
}

/** Matches a hash:// or https://www.hashforgamers.com link back to a destination. */
export function inspectLink(raw: string): { dest: DeepLinkDestination; values: Record<string, string> } | null {
  const text = raw.trim();
  if (text.startsWith("/")) {
    const dest = DESTINATIONS.find((d) => d.path === `route:${text}`);
    return dest ? { dest, values: {} } : null;
  }
  let url: URL;
  try {
    url = new URL(text);
  } catch {
    return null;
  }
  const segments =
    url.protocol === "hash:" || url.protocol === "hashforgamers:"
      ? [url.hostname, ...url.pathname.split("/")]
      : url.hostname.endsWith("hashforgamers.com")
        ? url.pathname.split("/")
        : null;
  if (!segments) return null;
  const path = segments.filter(Boolean).join("/");
  for (const dest of DESTINATIONS) {
    if (dest.path.startsWith("route:")) continue;
    const [templatePath, templateQuery = ""] = dest.path.split("?");
    const names: string[] = [];
    const pattern = new RegExp(
      `^${templatePath.replace(/[.*+?^$()|[\]\\]/g, "\\$&").replace(/\{(\w+)\}/g, (_m, name: string) => {
        names.push(name);
        return "([^/]+)";
      })}$`,
      "i",
    );
    const match = pattern.exec(path);
    if (!match) continue;
    const values: Record<string, string> = {};
    names.forEach((n, i) => (values[n] = decodeURIComponent(match[i + 1])));
    for (const pair of templateQuery.split("&").filter(Boolean)) {
      const key = pair.split("=")[0];
      values[key] = url.searchParams.get(key) ?? "";
    }
    if (missingParams(dest, values).length) continue;
    return { dest, values };
  }
  return null;
}
