---
name: forge-docs
description: Documentation lookup skill using Context7 MCP - prevents API hallucination for external libraries
globs: ["**/*.dart", "**/*.rs", "**/*.toml", "**/*.yaml", "pubspec.yaml", "Cargo.toml"]
alwaysApply: false
---

# Forge Docs Skill (Context7 Integration)

## Activation Triggers
Activate when:
- Using any external library or package
- Importing a new dependency
- Calling unfamiliar APIs
- Library version changed recently

## The Problem This Solves
Training data for LLMs is frozen at a cutoff date. Library APIs change:
- flutter_bloc 7 → 8: breaking changes
- tonic 0.10 → 0.11: API changes
- retrofit 3 → 4: annotation changes

**Never trust memory for external library APIs.** Always verify.

## Context7 Protocol

### Step 1: Identify the Library
What external library are you about to use?
Example: "I need to use flutter_bloc for state management"

### Step 2: Resolve Library ID
```
mcp__context7__resolve-library-id({
  libraryName: "flutter_bloc"
})
→ Returns: "/flutter/bloc" (or similar ID)
```

### Step 3: Query Documentation
```
mcp__context7__query-docs({
  context7CompatibleLibraryID: "/flutter/bloc",
  topic: "BlocProvider, BlocBuilder, state management"
})
→ Returns: current API documentation
```

### Step 4: Use Returned Docs
Use ONLY the documentation returned by Context7.
Do NOT mix with training data.
If Context7 returns no results → note `[DOCS NOT FOUND: library-name]` and ask user.

## Common Library Lookups

For Flutter projects, always look up:
- `flutter_bloc` — BlocProvider, BlocBuilder, BlocListener, BlocSelector
- `get_it` / `injectable` — DI setup, annotations
- `retrofit` / `dio` — API generation, interceptors
- `mocktail` — Mock setup, when/thenAnswer
- `go_router` — Routes, guards, deep linking
- `freezed` — @freezed, copyWith, union types

For Rust projects, always look up:
- `tonic` — service implementation, interceptors
- `tokio` — spawn, channels, select!
- `sqlx` — queries, transactions, migrations
- `tracing` — instrument, spans, events
- `cucumber` — World, steps, tags

## Rule
**NEVER** write code using an external library without first invoking Context7.
Training data = past. Context7 = present. Use the present.
