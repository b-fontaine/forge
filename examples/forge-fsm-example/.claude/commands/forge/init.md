# /forge:init — Initialize Forge Framework

## Purpose
Set up Forge in a new or existing project.

## Detection: New vs Existing Project

Check for: `pubspec.yaml`, `Cargo.toml`, `package.json`, `*.py`, source files
- If NO source files found → **New Project Flow**
- If source files found → **Existing Project Flow**

## New Project Flow

1. **Ask**: "Describe your project in 1-2 sentences. What does it do and for whom?"

2. **Recommend stack based on description**:
   - Mobile/web app with backend → Flutter + Rust gRPC + Kong + Docker/K8s
   - Simple mobile/web app → Flutter + Firebase
   - CLI tool → Rust standalone with clap
   - Full platform → Flutter + Rust + Kong + Temporal + Docker/K8s

3. **Create constitution**: Copy `.forge/constitution.md` template (already exists from Forge installation)

4. **Create product files**: Initialize `.forge/product/mission.md`, `roadmap.md`, `tech-stack.md` with project info

5. **Apply relevant standards**: Based on chosen stack, ensure index.yml references correct standards

6. **Output**: Summary of what was created, next step: `/forge:vision`

## Existing Project Flow

1. **Scan codebase**: Look at file extensions, config files, dependencies
   - `pubspec.yaml` → Flutter project
   - `Cargo.toml` → Rust project  
   - Both → Full-stack

2. **Adapt constitution**: The existing constitution already covers the detected stack

3. **Run `/forge:discover`**: Automatically scan for existing conventions

4. **Extract mission from README**: If README.md exists, propose a mission statement from it

5. **Output**: "Forge initialized for existing [Flutter/Rust/Full-stack] project. Run `/forge:discover` to capture existing conventions, or `/forge:vision` to define your product."

## Archetype Branch: `--archetype full-stack-monorepo`

<!-- Audit: B.1.2 (part of b1-scaffolder) -->

When invoked as `/forge:init --archetype full-stack-monorepo <project-name> --org <reverse-domain>`, delegate to `.forge/scripts/scaffolder/init.sh`. This script generates a full-stack-monorepo project (Flutter frontend + Rust backend + Infra + protos) that satisfies the archetype contract archived in `.forge/specs/full-stack-monorepo.md` (FR-GL-001..008).

### Prerequisites

The scaffolder aborts with a clear error if any of these tools is missing or below minimum version:

- `flutter` ≥ 3.24 (`flutter --version`)
- `cargo` ≥ 1.80 (`cargo --version`)
- `buf` ≥ 1.30 (`buf --version`)

### Usage

```bash
bash .forge/scripts/scaffolder/init.sh <project-name> \
  --org <reverse-domain> \
  [--target-dir <path>] \
  [--force] \
  [--dry-run]
```

- `<project-name>` — required positional. Regex-validated: `^[a-z][a-z0-9_-]{0,39}$`. Used as the target directory name (when `--target-dir` is omitted) and substituted into templates.
- `--org <reverse-domain>` — required. Regex-validated: `^[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)+$`. Passed to `flutter create --org` and substituted into templates.
- `--target-dir <path>` — where to scaffold. Default: `./<project-name>`.
- `--force` — required if the target directory exists or template files collide. NEVER overwrites output of `flutter create` or `cargo new`.
- `--dry-run` — print the sequence without executing anything.

### Sequence (non-negotiable per audit rule B.5.6)

1. Validate arguments, tool versions, target-dir collision.
2. Copy framework assets (`.forge/`, `.claude/`, `.mcp.json`, `docs/`) from the Forge source repo, stripping runtime state (`.forge/{changes,_memory,specs,product}`, `.claude/settings.local.json`).
3. `flutter create frontend --org <reverse-domain> --platforms android,ios,web --project-name <project_name_snake>_frontend`.
4. Invoke `.forge/scripts/scaffolder/overlay.sh` to apply all archetype templates listed in `scaffold-plan.yaml` (root CLAUDE.md, Taskfile, docker-compose, nested CLAUDE.md, backend Cargo workspace manifest, infra stubs, proto seed). Records tool versions in `.forge/scaffold-manifest.yaml`.
5. `cargo new --lib` for each workspace crate (`domain`, `application`, `grpc-api`, `infrastructure`) + `cargo new` for `bin-server`. Cargo auto-joins the workspace declared in step 4.
6. `buf lint` on the seed proto (WARN on failure; non-fatal on the seed commit).
7. Run `validate-foundations.sh` on the scaffolded target. **FAIL** aborts with exit code 7 and the scaffolded tree preserved for inspection.

### Output

On success:

```
✓ Scaffold complete : /abs/path/to/<project-name>

Next steps :
  cd <project-name>
  cp .env.example .env            # fill in real values
  task dev:up                     # start local stack
  cd frontend && flutter run      # run the app
```

On failure:

- Tool missing or below min version → exit 5 (`init.sh: flutter 3.10.0 < 3.24.0`).
- Invalid project-name or reverse-domain → exit 3 (delegated to overlay.sh regex validator).
- Target directory collides without `--force` → exit 6.
- `validate-foundations.sh` FAILs on the scaffolded tree → exit 7, `[SCAFFOLD VALIDATION FAILED]` banner, tree preserved.

### Testing

- `bash .forge/scripts/tests/scaffolder.test.sh --level 2` — plan + overlay checks (no external tools).
- `bash .forge/scripts/tests/scaffolder.test.sh --require-external-tools` — full L1 + L2 + L3 (21 scenarios, ~3s on a warm machine).
- See `.forge/changes/b1-scaffolder/features/b1-scaffolder.feature` for the AC scenarios in Gherkin.
