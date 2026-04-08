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
