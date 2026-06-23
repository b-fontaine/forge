# /forge:discover — Discover Existing Conventions

## Purpose
Scan an existing codebase to extract and document tribal knowledge as Forge standards.

## Discovery Process

### Step 1: File Scan
Scan these configuration files:
- `pubspec.yaml` → Flutter dependencies → state management, DI, networking patterns
- `Cargo.toml` / `Cargo.lock` → Rust dependencies → async runtime, HTTP, DB
- `analysis_options.yaml` → Flutter lint rules
- `.clippy.toml` → Rust lint config
- `docker-compose.yml` → Infrastructure setup
- `*.proto` → gRPC service definitions
- `*.feature` → Existing BDD scenarios

### Step 2: Source File Sample
Read 10-20 representative source files:
- State management: how are BLoCs/Cubits structured?
- Error handling: Either? exceptions? Result?
- DI: get_it? provider? manual?
- Testing: what test utilities are used?
- Naming: what patterns are followed?

### Step 3: Identify Unusual Patterns
Look for patterns that differ from Forge defaults. Document as custom standards:
- Non-standard state management → `standards/flutter/state-management-custom.md`
- Custom error handling → `standards/rust/error-handling-custom.md`
- Domain-specific conventions → `standards/global/domain-conventions.md`

### Step 4: Ask Targeted Questions
For each unusual pattern found, ask:
"I noticed you use [pattern] for [concern]. Is this intentional? Should I document this as a team standard?"

### Step 5: Generate Standard Files
For each confirmed convention:
1. Create the standard file with the discovered rules
2. Add entry to `.forge/standards/index.yml`

### Step 6: Output Summary
"Discovered [N] conventions:
- [Standard 1]: [brief description]
- [Standard 2]: [brief description]
Next: `/forge:vision` to define your product mission"
