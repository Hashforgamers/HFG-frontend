import { getRemoteConfig } from "firebase-admin/remote-config";
import { getAdminApp } from "@/lib/firebase-admin";

/** App feature switches stored as Firebase Remote Config booleans. */
export const FLAGS = [
  {
    key: "tournaments_enabled",
    label: "Tournaments",
    description:
      "Compete tab, hosting, tournament invites and home sections. Hides the Me tab while on.",
    warning:
      "Cash prize pools and host earnings conflict with Google Play's real-money contest policy. Only turn this on where that's been cleared.",
  },
] as const;

export type FlagKey = (typeof FLAGS)[number]["key"];

export type FlagState = {
  key: FlagKey;
  enabled: boolean;
  updatedAt: string | null;
  updatedBy: string | null;
};

const isFlag = (key: string): key is FlagKey => FLAGS.some((f) => f.key === key);

export async function readFlags(): Promise<FlagState[]> {
  const template = await getRemoteConfig(getAdminApp()).getTemplate();
  const version = template.version;
  return FLAGS.map(({ key }) => {
    const value = template.parameters[key]?.defaultValue;
    return {
      key,
      enabled: !!value && "value" in value && value.value === "true",
      updatedAt: version?.updateTime ?? null,
      updatedBy: version?.updateUser?.email ?? null,
    };
  });
}

/** Sets one flag and publishes the template. The app applies it on next launch. */
export async function setFlag(key: string, enabled: boolean): Promise<void> {
  if (!isFlag(key)) throw new Error(`Unknown flag: ${key}`);
  const rc = getRemoteConfig(getAdminApp());
  const template = await rc.getTemplate();
  const meta = FLAGS.find((f) => f.key === key)!;
  template.parameters[key] = {
    ...template.parameters[key],
    defaultValue: { value: enabled ? "true" : "false" },
    valueType: "BOOLEAN",
    description: meta.description,
  };
  await rc.publishTemplate(template);
}
