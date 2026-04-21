const SEMVER_RE =
  /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/;

export function parseVersion(contents: string): string {
  const trimmed = contents.trim();
  if (!SEMVER_RE.test(trimmed)) {
    throw new Error(`invalid version: ${JSON.stringify(trimmed)}`);
  }
  return trimmed;
}
