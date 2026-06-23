//! Prompt audit (Article IX.6) + PII guard (Article XI.6).
//!
//! Every gateway call emits a prompt-audit record (`llm-gateway.md`): model,
//! tenant, tier, token counts, latency, provider, and the fallback-invocation
//! flag. PII is redacted/minimised BEFORE anything is logged (XI.6).

use rag::ComplianceTier;

/// The audit record emitted per gateway call. This is the evidence trail for
/// budgets, abuse, and AI-Act transparency (B.7.5 territory).
#[derive(Debug, Clone, PartialEq)]
pub struct PromptAudit {
    /// Upstream model id.
    pub model: String,
    /// Tenant the request is scoped to.
    pub tenant: String,
    /// Active compliance tier.
    pub tier: ComplianceTier,
    /// Prompt token count (estimated/measured).
    pub prompt_tokens: u32,
    /// Completion token count (0 when the fallback served the request).
    pub completion_tokens: u32,
    /// Whether the non-AI fallback was invoked (XI.5 metric).
    pub fallback_invoked: bool,
    /// Whether a streaming request was cancelled before completing (client Stop
    /// / unmount, B.7.10 FR-B7-10-015). Always `false` on the unary path.
    pub cancelled: bool,
}

/// Redact obvious PII before logging (Article XI.6 — "minimise PII ... before
/// logging"). Deliberately conservative: emails and what look like long digit
/// runs (cards / phone / national-id) are masked. Adopters extend per their DPA.
pub fn redact_pii(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    let mut chars = text.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '@' {
            // Mask an email: drop the local part already emitted, replace whole token.
            // Walk back over the just-emitted local part.
            while out
                .chars()
                .last()
                .map(|p| p.is_alphanumeric() || p == '.' || p == '_' || p == '-' || p == '+')
                .unwrap_or(false)
            {
                out.pop();
            }
            out.push_str("[redacted-email]");
            // Skip the domain.
            while chars
                .peek()
                .map(|p| p.is_alphanumeric() || *p == '.' || *p == '-')
                .unwrap_or(false)
            {
                chars.next();
            }
        } else {
            out.push(c);
        }
    }
    mask_digit_runs(&out)
}

/// Mask runs of 7+ digits (phone / card / id) as `[redacted-number]`.
fn mask_digit_runs(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    let mut run = String::new();
    for c in text.chars() {
        if c.is_ascii_digit() {
            run.push(c);
        } else {
            flush_run(&mut run, &mut out);
            out.push(c);
        }
    }
    flush_run(&mut run, &mut out);
    out
}

fn flush_run(run: &mut String, out: &mut String) {
    if run.len() >= 7 {
        out.push_str("[redacted-number]");
    } else {
        out.push_str(run);
    }
    run.clear();
}

/// Emit the prompt-audit record as a tracing span/event (IX.6). The record is
/// already PII-redacted by the caller; this never logs raw prompt text.
pub fn emit(audit: &PromptAudit) {
    tracing::info!(
        target: "llm_gateway::prompt_audit",
        model = %audit.model,
        tenant = %audit.tenant,
        tier = ?audit.tier,
        prompt_tokens = audit.prompt_tokens,
        completion_tokens = audit.completion_tokens,
        fallback_invoked = audit.fallback_invoked,
        cancelled = audit.cancelled,
        "prompt-audit"
    );
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn redacts_email_addresses() {
        let out = redact_pii("contact alice@example.com now");
        assert!(!out.contains("alice@example.com"));
        assert!(out.contains("[redacted-email]"));
        assert!(out.contains("contact"));
        assert!(out.contains("now"));
    }

    #[test]
    fn redacts_long_digit_runs() {
        let out = redact_pii("card 4111111111111111 ok");
        assert!(out.contains("[redacted-number]"));
        assert!(!out.contains("4111111111111111"));
    }

    #[test]
    fn keeps_short_numbers() {
        // Short numbers (e.g. "top 10") are not PII; leave them.
        let out = redact_pii("top 10 results");
        assert_eq!(out, "top 10 results");
    }
}
