import { getRemoteConfig, type RemoteConfigTemplate } from "firebase-admin/remote-config";
import { getAdminApp } from "@/lib/firebase-admin";

/** App feature switches stored as Firebase Remote Config booleans, per platform. */
export const FLAGS = [
  {
    key: "tournaments_enabled",
    label: "Tournaments",
    description:
      "Compete tab, hosting, tournament invites and home sections. Hides the Me tab while on.",
    warning:
      "Cash prize pools and host earnings conflict with Google Play's real-money contest policy. Keep Android off unless that has been cleared.",
  },
] as const;

export const PLATFORMS = [
  { id: "android", label: "Android", condition: "platform_android", expression: "device.os == 'android'" },
  { id: "ios", label: "iOS", condition: "platform_ios", expression: "device.os == 'ios'" },
] as const;

export type FlagKey = (typeof FLAGS)[number]["key"];
export type Platform = (typeof PLATFORMS)[number]["id"];

export type FlagState = {
  key: FlagKey;
  platforms: Record<Platform, boolean>;
  updatedAt: string | null;
  updatedBy: string | null;
};

const isFlag = (key: string): key is FlagKey => FLAGS.some((f) => f.key === key);
const isPlatform = (p: string): p is Platform => PLATFORMS.some((x) => x.id === p);

const valueOf = (v: unknown) =>
  !!v && typeof v === "object" && "value" in v && (v as { value: string }).value === "true";

export async function readFlags(): Promise<FlagState[]> {
  const template = await getRemoteConfig(getAdminApp()).getTemplate();
  const version = template.version;
  return FLAGS.map(({ key }) => {
    const p = template.parameters[key];
    const fallback = valueOf(p?.defaultValue);
    return {
      key,
      platforms: Object.fromEntries(
        PLATFORMS.map((pl) => {
          const conditional = p?.conditionalValues?.[pl.condition];
          return [pl.id, conditional ? valueOf(conditional) : fallback];
        }),
      ) as Record<Platform, boolean>,
      updatedAt: version?.updateTime ?? null,
      updatedBy: version?.updateUser?.email ?? null,
    };
  });
}

function ensureConditions(template: RemoteConfigTemplate) {
  for (const pl of PLATFORMS) {
    if (!template.conditions.some((c) => c.name === pl.condition)) {
      template.conditions.push({ name: pl.condition, expression: pl.expression });
    }
  }
}

/** Sets one flag on one platform and publishes. Apps apply it on next launch. */
export async function setFlag(key: string, platform: string, enabled: boolean): Promise<void> {
  if (!isFlag(key)) throw new Error(`Unknown flag: ${key}`);
  if (!isPlatform(platform)) throw new Error(`Unknown platform: ${platform}`);
  const rc = getRemoteConfig(getAdminApp());
  const template = await rc.getTemplate();
  ensureConditions(template);
  const meta = FLAGS.find((f) => f.key === key)!;
  const current = template.parameters[key];
  const fallback = valueOf(current?.defaultValue);
  const conditionalValues = { ...(current?.conditionalValues ?? {}) };
  // Pin both platforms explicitly so flipping one never moves the other.
  for (const pl of PLATFORMS) {
    if (!conditionalValues[pl.condition]) {
      conditionalValues[pl.condition] = { value: fallback ? "true" : "false" };
    }
  }
  const target = PLATFORMS.find((p) => p.id === platform)!;
  conditionalValues[target.condition] = { value: enabled ? "true" : "false" };
  template.parameters[key] = {
    ...current,
    // Anything else (web, unknown) stays off.
    defaultValue: { value: "false" },
    conditionalValues,
    valueType: "BOOLEAN",
    description: meta.description,
  };
  await rc.validateTemplate(template);
  await rc.publishTemplate(template);
}
