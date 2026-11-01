import Anthropic from "@anthropic-ai/sdk";
import { zodOutputFormat } from "@anthropic-ai/sdk/helpers/zod";
import { z } from "zod";
import { DESTINATIONS } from "@/lib/deeplinks";

const routable = DESTINATIONS.filter((d) => d.opens);

const Variant = z.object({
  angle: z.string().describe("Two or three words naming the hook, e.g. 'FOMO', 'Streak at risk'."),
  title: z.string().describe("Max 50 characters."),
  body: z.string().describe("Max 140 characters."),
  destination_key: z.enum(routable.map((d) => d.key) as [string, ...string[]]),
  destination_params: z
    .array(z.object({ key: z.string(), value: z.string() }))
    .describe("Values for the destination's params; use ids from the brief, else leave empty."),
  utm_campaign: z.string().describe("snake_case slug for analytics."),
  channel: z.enum(["system_channel", "offer_channel", "contest_channel"]),
  why: z.string().describe("One sentence on why this should get opens."),
});
const Output = z.object({ variants: z.array(Variant) });
export type AiVariant = z.infer<typeof Variant>;

const SYSTEM = `You write push notifications for Hash For Gamers (HFG), an Indian gaming app: gaming cafe bookings, Hash coins wallet with daily streaks and rewards, a merch/gaming store (Hash Store), online Ludo, Snakes & Ladders, Wordly, Arrow Escape, Flappy Birds and an arcade leaderboard. Users are mostly 16-30, in Mumbai (Mira Road first), comfortable with English and Hinglish.

Rules:
- Title at most 50 characters, body at most 140. Front-load the hook; the first 35 characters of the body show on a locked screen.
- Concrete over vague: name the game, the reward, the number. Never invent prices, discounts, prizes or ids that are not in the brief.
- One clear action per notification. No clickbait that the landing screen cannot deliver.
- Emoji: at most one, only where it adds meaning.
- Pick destination_key only from the list below; it must be where the action actually happens.
- Each variant must use a genuinely different angle so they can be A/B tested.

Destinations (key: what it opens, params):
${routable.map((d) => `- ${d.key}: ${d.label}. ${d.hint}${d.params.length ? ` Params: ${d.params.map((p) => p.key).join(", ")}.` : ""}`).join("\n")}`;

export type Brief = {
  goal: string;
  audience: string;
  tone: string;
  language: "English" | "Hinglish" | "Hindi";
  count: number;
  current?: { title: string; body: string };
};

export async function writeVariants(brief: Brief): Promise<AiVariant[]> {
  if (!process.env.ANTHROPIC_API_KEY) throw new Error("ANTHROPIC_API_KEY is not set on the server.");
  const client = new Anthropic();
  const response = await client.messages.parse({
    model: "claude-opus-5-5",
    max_tokens: 16000,
    output_config: { effort: "low", format: zodOutputFormat(Output) },
    system: SYSTEM,
    messages: [
      {
        role: "user",
        content: [
          `Goal: ${brief.goal}`,
          `Audience: ${brief.audience || "all users"}`,
          `Tone: ${brief.tone || "playful, confident"}`,
          `Language: ${brief.language}`,
          brief.current?.title ? `Improve on this draft:\nTitle: ${brief.current.title}\nBody: ${brief.current.body}` : "",
          `Write ${Math.min(Math.max(brief.count, 1), 6)} variants.`,
        ]
          .filter(Boolean)
          .join("\n"),
      },
    ],
  });
  if (response.stop_reason === "refusal") throw new Error("The model declined this brief. Rephrase it.");
  if (!response.parsed_output) throw new Error("The model returned no usable variants. Try again.");
  return response.parsed_output.variants;
}

const TrendCopy = z.object({
  title: z.string().describe("Max 50 characters."),
  body: z.string().describe("Max 140 characters."),
});

/** Facts the trending autopilot found; the copy may only use these. */
export type TrendFacts = { cafeName: string; viewersToday: number; bookingsToday: number };

/**
 * Copy for an automatic "this cafe is trending" broadcast. Cafes have no deep
 * link yet, so the tap opens Home (cafe list) and the copy must not promise
 * to open the cafe page.
 */
export async function writeTrendCopy(facts: TrendFacts): Promise<{ title: string; body: string }> {
  if (!process.env.ANTHROPIC_API_KEY) throw new Error("ANTHROPIC_API_KEY is not set on the server.");
  const response = await new Anthropic().messages.parse({
    model: "claude-opus-5-5",
    max_tokens: 4000,
    output_config: { effort: "low", format: zodOutputFormat(TrendCopy) },
    system: SYSTEM,
    messages: [
      {
        role: "user",
        content: [
          "Write one push for all users: a gaming cafe is trending on Hash today.",
          `Cafe: ${facts.cafeName}`,
          `Distinct players who checked it out in the last 24 hours: ${facts.viewersToday}`,
          facts.bookingsToday > 0 ? `Bookings confirmed on Hash in the last 24 hours (all cafes): ${facts.bookingsToday}` : "",
          "Use only these numbers. The tap opens the Hash home screen with the cafe list, not the cafe page, so do not say 'tap to open' the cafe.",
          "Tone: playful, confident, light FOMO. English or light Hinglish.",
        ]
          .filter(Boolean)
          .join("\n"),
      },
    ],
  });
  if (!response.parsed_output) throw new Error("The model returned no usable copy.");
  return response.parsed_output;
}
