// Audit: B.7.2 (b7-2-scaffolder, Phase 3) — ai-native-rag RAG query landing route
//        + B.7.10 (b7-10-streaming) — progressive streaming render + cancel + retry
// Structural precedent: full-stack-monorepo/2.0.0/frontend/web-public/src/routes/index.tsx.tmpl
// Standard: .forge/standards/web-frontend.yaml
//
// Streaming RAG query UI (B.7.10): an input → a server-streaming Connect call
// (RagService.QueryStream) consumed with `for await`, appending each token_delta
// to a Qwik signal so the answer renders PROGRESSIVELY (Article XI.4 — no
// blocking synchronous AI call). A Stop control cancels the in-flight stream via
// an AbortController; the stream is also cancelled on unmount (Qwik cleanup —
// cancel-on-unmount), so no orphaned stream survives navigation. On repeated
// transient stream errors the UI applies exponential-backoff retry and, on
// exhaustion, DEGRADES to the unary query() path (the UI-layer Article XI.5
// fallback: SSE-class → unary → non-AI fallback answer). The fallbackUsed
// indicator surfaces the XI.5 non-AI fallback whichever path served the answer.
import {
  component$,
  useSignal,
  useVisibleTask$,
  noSerialize,
  $,
} from "@builder.io/qwik";
import type { NoSerialize } from "@builder.io/qwik";
import type { DocumentHead } from "@builder.io/qwik-city";
import {
  query,
  queryStream,
  exponentialBackoffMs,
  DEFAULT_RETRY_POLICY,
} from "../lib/connect-client";

export default component$(() => {
  const question = useSignal<string>("");
  // Progressively-rendered answer text (token deltas append here as they arrive).
  const answer = useSignal<string>("");
  const sources = useSignal<{ documentId: string; content: string; score: number }[]>([]);
  const fallbackUsed = useSignal<boolean>(false);
  const streaming = useSignal<boolean>(false);
  const error = useSignal<string>("");

  // The in-flight stream's AbortController, kept in a signal so the Stop button
  // and the unmount-cleanup task can both reach it (FR-B7-10-022).
  const controller = useSignal<NoSerialize<AbortController> | undefined>(undefined);

  // cancel-on-unmount: when the component is torn down (navigation away), abort
  // any in-flight stream so it does not outlive the route (FR-B7-10-022).
  useVisibleTask$(({ cleanup }) => {
    cleanup(() => controller.value?.abort());
  });

  // Stop control handler — aborts the in-flight stream (FR-B7-10-022).
  const stop = $(() => {
    controller.value?.abort();
    streaming.value = false;
  });

  // Run the streaming query with exponential-backoff retry on transient stream
  // errors; on exhausting the bounded attempts, degrade to the unary query()
  // path (UI-layer XI.5 fallback, FR-B7-10-023).
  const ask = $(async () => {
    if (question.value.trim() === "") return;
    answer.value = "";
    sources.value = [];
    fallbackUsed.value = false;
    error.value = "";
    streaming.value = true;

    const policy = DEFAULT_RETRY_POLICY;
    for (let attempt = 0; attempt < policy.maxAttempts; attempt++) {
      const ac = new AbortController();
      controller.value = noSerialize(ac);
      try {
        for await (const chunk of queryStream(question.value, 0, ac.signal)) {
          if (chunk.sources.length > 0) sources.value = chunk.sources;
          if (chunk.tokenDelta !== "") answer.value += chunk.tokenDelta;
          if (chunk.fallbackUsed) fallbackUsed.value = true;
          if (chunk.done) {
            streaming.value = false;
            return;
          }
        }
        // Stream ended cleanly (or was aborted by Stop/unmount) — done.
        streaming.value = false;
        return;
      } catch (e) {
        // Aborted by the user (Stop) / unmount — do not retry or degrade.
        if (ac.signal.aborted) {
          streaming.value = false;
          return;
        }
        // Transient stream error: back off exponentially, then retry the stream.
        if (attempt < policy.maxAttempts - 1) {
          answer.value = "";
          await new Promise((r) => setTimeout(r, exponentialBackoffMs(attempt, policy)));
          continue;
        }
        // Retries exhausted → degrade to the unary query() path (XI.5).
        try {
          const res = await query(question.value);
          answer.value = res.answer;
          sources.value = res.sources;
          fallbackUsed.value = res.fallbackUsed;
        } catch (e2) {
          error.value = e2 instanceof Error ? e2.message : String(e2);
        } finally {
          streaming.value = false;
        }
        return;
      }
    }
  });

  return (
    <main>
      <h1>forge-rag-example — RAG query</h1>
      <p>
        Ask a question; the backend streams a retrieval-augmented answer through
        the in-repo LLM gateway, rendering it token-by-token. If the AI upstream
        is unavailable, a non-AI fallback answer is served (Article XI.5) —
        surfaced by the indicator below. The Stop control cancels an in-flight
        stream.
      </p>

      <form preventdefault:submit onSubmit$={ask}>
        <input
          type="text"
          name="question"
          placeholder="Ask a question…"
          value={question.value}
          onInput$={(_, el) => (question.value = el.value)}
        />
        <button type="submit" disabled={streaming.value}>
          {streaming.value ? "Streaming…" : "Query"}
        </button>
        {streaming.value && (
          <button type="button" class="stop" onClick$={stop}>
            Stop
          </button>
        )}
      </form>

      {error.value !== "" && (
        <p role="alert" class="error">
          Query failed: {error.value}
        </p>
      )}

      {(answer.value !== "" || sources.value.length > 0) && (
        <section>
          {fallbackUsed.value && (
            <p class="fallback-indicator" role="status">
              ⚠ Non-AI fallback answer (the AI upstream was unavailable or
              over budget — Article XI.5).
            </p>
          )}
          <h2>Answer</h2>
          {/* Progressive render: token deltas append to `answer` as they stream. */}
          <p aria-live="polite">{answer.value}</p>

          {sources.value.length > 0 && (
            <>
              <h3>Sources</h3>
              <ul>
                {sources.value.map((s) => (
                  <li key={s.documentId}>
                    <strong>{s.documentId}</strong> (score{" "}
                    {s.score.toFixed(3)}): {s.content}
                  </li>
                ))}
              </ul>
            </>
          )}
        </section>
      )}
    </main>
  );
});

export const head: DocumentHead = {
  title: "forge-rag-example — RAG query",
  meta: [
    {
      name: "description",
      content: "AI-native streaming RAG query surface for forge-rag-example (Qwik City).",
    },
  ],
};
