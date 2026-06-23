//! Chunking — split documents by semantic unit with a token-budgeted overlap
//! (`rag-patterns.md`: "Chunk by semantic unit ... keep a token-budgeted
//! overlap (≈10–20%) so context isn't severed mid-thought").
//!
//! This is a deliberately simple, deterministic word-window chunker (NFR
//! determinism). Adopters swap in a semantic splitter; the contract (overlap,
//! provenance ordinal) is what the pipeline depends on.

/// One chunk of a source document, carrying its ordinal for provenance.
#[derive(Debug, Clone, PartialEq)]
pub struct Chunk {
    /// 0-based position of this chunk within its source document.
    pub ordinal: usize,
    /// Chunk text.
    pub text: String,
}

/// Split `text` into word-windows of `max_words` with `overlap` words shared
/// between consecutive chunks. `overlap` is clamped below `max_words` so the
/// window always advances (no infinite loop).
pub fn chunk_words(text: &str, max_words: usize, overlap: usize) -> Vec<Chunk> {
    let words: Vec<&str> = text.split_whitespace().collect();
    if words.is_empty() || max_words == 0 {
        return Vec::new();
    }
    let overlap = overlap.min(max_words.saturating_sub(1));
    let step = max_words - overlap;

    let mut chunks = Vec::new();
    let mut start = 0;
    let mut ordinal = 0;
    while start < words.len() {
        let end = (start + max_words).min(words.len());
        chunks.push(Chunk {
            ordinal,
            text: words[start..end].join(" "),
        });
        ordinal += 1;
        if end == words.len() {
            break;
        }
        start += step;
    }
    chunks
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_input_yields_no_chunks() {
        assert!(chunk_words("", 10, 2).is_empty());
        assert!(chunk_words("hello world", 0, 0).is_empty());
    }

    #[test]
    fn windows_advance_and_overlap() {
        let chunks = chunk_words("a b c d e f", 3, 1);
        // step = 3 - 1 = 2 → windows [a b c], [c d e], [e f]
        assert_eq!(chunks.len(), 3);
        assert_eq!(chunks[0].text, "a b c");
        assert_eq!(chunks[1].text, "c d e");
        assert_eq!(chunks[2].text, "e f");
        assert_eq!(chunks[2].ordinal, 2);
    }

    #[test]
    fn overlap_clamped_below_window_so_it_terminates() {
        // overlap >= max_words would stall; it must be clamped.
        let chunks = chunk_words("a b c d", 2, 5);
        assert!(!chunks.is_empty());
        assert_eq!(chunks[0].text, "a b");
    }
}
