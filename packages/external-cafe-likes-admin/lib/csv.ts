export function toCsv(
  rows: Array<Record<string, string | number | null | undefined>>,
) {
  if (rows.length === 0) {
    return "";
  }

  const headers = Object.keys(rows[0]);
  const escape = (value: string | number | null | undefined) => {
    const raw = value == null ? "" : String(value);
    const escaped = raw.replace(/"/g, '""');
    return `"${escaped}"`;
  };

  return [
    headers.join(","),
    ...rows.map((row) => headers.map((header) => escape(row[header])).join(",")),
  ].join("\n");
}
