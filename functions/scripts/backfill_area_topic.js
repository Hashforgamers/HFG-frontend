// Subscribe existing users' FCM tokens to an area topic (e.g. area_mira_road).
// Tokens come from a file, one per line, exported from the booking backend DB.
//
// Usage (from functions/):
//   GOOGLE_APPLICATION_CREDENTIALS=sa.json node scripts/backfill_area_topic.js tokens.txt mira_road         # dry run
//   GOOGLE_APPLICATION_CREDENTIALS=sa.json node scripts/backfill_area_topic.js tokens.txt mira_road --apply
const fs = require("fs");

const BATCH = 1000; // FCM limit per subscribeToTopic call

function readTokens(path) {
  return [...new Set(fs.readFileSync(path, "utf8").split(/\r?\n/).map((t) => t.trim()).filter(Boolean))];
}

function chunk(arr, n) {
  const out = [];
  for (let i = 0; i < arr.length; i += n) out.push(arr.slice(i, n + i));
  return out;
}

async function main() {
  const [file, area, flag] = process.argv.slice(2);
  if (!file || !/^[a-z0-9_]+$/.test(area || "")) {
    console.error("usage: backfill_area_topic.js <tokens.txt> <area_slug> [--apply]");
    process.exit(1);
  }
  const topic = `area_${area}`;
  const tokens = readTokens(file);
  console.log(`${tokens.length} unique tokens -> ${topic}`);
  if (flag !== "--apply") return console.log("dry run; pass --apply to subscribe");

  const admin = require("firebase-admin");
  admin.initializeApp();
  let ok = 0, bad = 0;
  for (const part of chunk(tokens, BATCH)) {
    const res = await admin.messaging().subscribeToTopic(part, topic);
    ok += res.successCount;
    bad += res.failureCount;
    res.errors.forEach((e) => console.warn(`fail ${part[e.index].slice(0, 12)}…: ${e.error.code}`));
  }
  console.log(`done: ${ok} subscribed, ${bad} failed (usually stale/uninstalled tokens)`);
}

module.exports = { readTokens, chunk };
if (require.main === module) main().catch((e) => { console.error(e); process.exit(1); });
