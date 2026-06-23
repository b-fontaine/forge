// Audit: B.7.2 (b7-2-scaffolder, Phase 3) — ai-native-rag Qwik web-public root
// Structural precedent: full-stack-monorepo/2.0.0/frontend/web-public/src/root.tsx.tmpl
// Standard: .forge/standards/web-frontend.yaml
// Minimal skeleton: QwikCityProvider + RouterOutlet. Adopters add a RouterHead,
// ServiceWorkerRegister (PWA), and global.css here.
import { component$ } from "@builder.io/qwik";
import { QwikCityProvider, RouterOutlet } from "@builder.io/qwik-city";

export default component$(() => {
  return (
    <QwikCityProvider>
      <head>
        <meta charSet="utf-8" />
        <title>forge-rag-example — RAG web-public</title>
      </head>
      <body lang="en-us">
        <RouterOutlet />
      </body>
    </QwikCityProvider>
  );
});
