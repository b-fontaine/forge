// Audit: B.7.2 (b7-2-scaffolder, Phase 3) — ai-native-rag Qwik web-public SSR entry
// Structural precedent: full-stack-monorepo/2.0.0/frontend/web-public/src/entry.ssr.tsx.tmpl
// Standard: .forge/standards/web-frontend.yaml
// renderToStream is the server-side render entry used by the `vite --mode ssr`
// dev server and `qwik build` SSG/SSR pipeline.
import {
  renderToStream,
  type RenderToStreamOptions,
} from "@builder.io/qwik/server";
import Root from "./root";

export default function (opts: RenderToStreamOptions) {
  return renderToStream(<Root />, {
    ...opts,
    containerAttributes: {
      lang: "en-us",
      ...opts.containerAttributes,
    },
  });
}
