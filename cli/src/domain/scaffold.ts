export type Op =
  | { type: "copy"; src: string; dst: string }
  | { type: "scaffold"; src: string; dst: string }
  | { type: "skip"; dst: string; reason: string }
  | { type: "ensure-dir"; dst: string };

export interface PlanInput {
  sourceFiles: string[];
  targetExisting: ReadonlySet<string>;
  force: boolean;
}

const EXCLUDED_PATHS: ReadonlySet<string> = new Set([
  ".claude/settings.local.json",
]);

const EXCLUDED_PREFIXES: readonly string[] = [
  ".forge/product/",
  ".forge/_memory/",
  ".forge/changes/",
  ".forge/specs/",
];

const PRODUCT_TEMPLATE_PREFIX = ".forge/templates/product/";

function isExcluded(path: string): boolean {
  if (EXCLUDED_PATHS.has(path)) return true;
  return EXCLUDED_PREFIXES.some((p) => path.startsWith(p));
}

function productTargetFor(templatePath: string): string | undefined {
  if (!templatePath.startsWith(PRODUCT_TEMPLATE_PREFIX)) return undefined;
  const filename = templatePath.slice(PRODUCT_TEMPLATE_PREFIX.length);
  if (!filename.endsWith(".md") || filename.includes("/")) return undefined;
  return `.forge/product/${filename}`;
}

export function scaffoldPlan(input: PlanInput): Op[] {
  const ops: Op[] = [];
  for (const path of input.sourceFiles) {
    if (isExcluded(path)) continue;

    if (input.targetExisting.has(path) && !input.force) {
      ops.push({ type: "skip", dst: path, reason: "exists" });
    } else {
      ops.push({ type: "copy", src: path, dst: path });
    }

    const productDst = productTargetFor(path);
    if (productDst !== undefined) {
      if (input.targetExisting.has(productDst)) {
        ops.push({
          type: "skip",
          dst: productDst,
          reason: "user-content-preserved",
        });
      } else {
        ops.push({ type: "scaffold", src: path, dst: productDst });
      }
    }
  }
  return ops;
}
