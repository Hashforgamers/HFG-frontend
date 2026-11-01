// Self-check: node --experimental-strip-types lib/deeplinks.check.ts
import assert from "node:assert/strict";
import { DESTINATIONS, buildLink, inspectLink } from "./deeplinks.ts";

const byKey = (k: string) => DESTINATIONS.find((d) => d.key === k)!;

const product = buildLink(byKey("shop_product"), { product_id: "p 1" }, { source: "push", campaign: "diwali" });
assert.equal(product.value, "hash://shop/product/p%201?utm_source=push&utm_campaign=diwali");
assert.equal(product.web, "https://www.hashforgamers.com/shop/product/p%201?utm_source=push&utm_campaign=diwali");

const team = buildLink(byKey("team_join"), { event_id: "e1", team_id: "t1" });
assert.equal(team.value, "hash://team/join?event_id=e1&team_id=t1");

assert.deepEqual(buildLink(byKey("chat"), {}), { kind: "route", value: "/chat", web: null });

// Round-trips, both schemes.
for (const dest of DESTINATIONS) {
  const values = Object.fromEntries(dest.params.map((p) => [p.key, p.placeholder]));
  const built = buildLink(dest, values);
  for (const link of [built.value, built.web].filter(Boolean) as string[]) {
    const found = inspectLink(link);
    assert.equal(found?.dest.key, dest.key, `${link} -> ${found?.dest.key}`);
    assert.deepEqual(found?.values, values);
  }
}
assert.equal(inspectLink("hash://nope"), null);
assert.equal(inspectLink("https://evil.com/wallet"), null);
console.log("deeplinks ok");
