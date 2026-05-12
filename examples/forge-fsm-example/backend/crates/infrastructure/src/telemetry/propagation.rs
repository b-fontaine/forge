//! Propagation carriers — W3C traceparent injection / extraction adapters.
//!
//! <!-- Audit: T.5 (t5-otel-app) — FR-T5-OTA-022 / FR-T5-OTA-023 -->
//!
//! Mirrors the helper shapes in `rust/opentelemetry.md` §HTTP Client
//! Instrumentation and §Context Propagation in gRPC. Ships in Phase B even
//! though demo-005 has no outbound HTTP yet — adopters who copy-paste the
//! example get a re-usable propagation toolkit.
//!
//! No PII : carriers operate purely on header / metadata maps ; they never
//! dereference span attributes.

use http::HeaderMap;
use opentelemetry::propagation::{Extractor, Injector};
use tonic::metadata::MetadataMap;

/// `Injector` adapter for outbound HTTP (`http::HeaderMap`).
///
/// Used with `TraceContextPropagator::inject_context` to write the
/// `traceparent` header on outbound `reqwest` / `connectrpc` client calls.
pub struct HeaderMapCarrier<'a>(pub &'a mut HeaderMap);

impl Injector for HeaderMapCarrier<'_> {
    fn set(&mut self, key: &str, value: String) {
        if let Ok(name) = http::header::HeaderName::from_bytes(key.as_bytes())
            && let Ok(val) = http::header::HeaderValue::from_str(&value)
        {
            self.0.insert(name, val);
        }
    }
}

/// `Extractor` adapter for inbound HTTP (`http::HeaderMap`).
pub struct HeaderMapExtractor<'a>(pub &'a HeaderMap);

impl Extractor for HeaderMapExtractor<'_> {
    fn get(&self, key: &str) -> Option<&str> {
        self.0.get(key).and_then(|v| v.to_str().ok())
    }

    fn keys(&self) -> Vec<&str> {
        self.0.keys().map(|k| k.as_str()).collect()
    }
}

/// `Extractor` adapter for inbound tonic gRPC (`tonic::metadata::MetadataMap`).
///
/// Per `rust/opentelemetry.md` §Context Propagation in gRPC.
pub struct MetadataMapCarrier<'a>(pub &'a MetadataMap);

impl Extractor for MetadataMapCarrier<'_> {
    fn get(&self, key: &str) -> Option<&str> {
        self.0.get(key).and_then(|v| v.to_str().ok())
    }

    fn keys(&self) -> Vec<&str> {
        self.0
            .keys()
            .map(|k| match k {
                tonic::metadata::KeyRef::Ascii(k) => k.as_str(),
                tonic::metadata::KeyRef::Binary(k) => k.as_str(),
            })
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn header_map_carrier_round_trips_traceparent() {
        let mut headers = HeaderMap::new();
        let mut carrier = HeaderMapCarrier(&mut headers);
        carrier.set(
            "traceparent",
            "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01".to_string(),
        );
        let extracted = HeaderMapExtractor(&headers);
        assert_eq!(
            extracted.get("traceparent"),
            Some("00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01")
        );
    }

    #[test]
    fn metadata_map_carrier_extracts_traceparent() {
        let mut md = MetadataMap::new();
        md.insert(
            "traceparent",
            "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01"
                .parse()
                .unwrap(),
        );
        let carrier = MetadataMapCarrier(&md);
        assert_eq!(
            carrier.get("traceparent"),
            Some("00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01")
        );
        assert!(carrier.keys().contains(&"traceparent"));
    }
}
