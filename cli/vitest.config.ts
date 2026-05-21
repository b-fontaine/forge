import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["test/**/*.test.ts"],
    environment: "node",
    // <!-- Audit: T5.3.3 (t5-3-3-vitest-bundle-preflight) — rebundle cli/assets/ before any test -->
    globalSetup: "./test/global-setup.ts",
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov"],
      include: ["src/**/*.ts"],
      exclude: ["src/index.ts", "src/cli.ts"],
    },
  },
});
