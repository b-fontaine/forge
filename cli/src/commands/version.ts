import { parseVersion } from "../domain/version.js";

export interface VersionCommandDeps {
  readFile(path: string): Promise<string>;
  writeLine(text: string): void;
  writeError(text: string): void;
  versionFilePath: string;
}

export async function versionCommand(
  deps: VersionCommandDeps,
): Promise<number> {
  try {
    const contents = await deps.readFile(deps.versionFilePath);
    const version = parseVersion(contents);
    deps.writeLine(version);
    return 0;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    deps.writeError(message);
    return 1;
  }
}
