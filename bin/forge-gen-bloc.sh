#!/usr/bin/env bash
# Forge — generate a flutter_bloc feature from a local declarative descriptor.
# <!-- Audit: B.9.5 (b9-5-bloc-generator, FR-B95-001..009) -->
#
# Produces Event / State / Bloc + a bloc_test scaffold for one feature of a
# `mobile-pwa-first` (or `mobile-only`) project.
#
# ── WHY A LOCAL DESCRIPTOR, AND NOT PROTO MESSAGES ───────────────────────────
#
# The roadmap specified these generators as reading the proto messages. This archetype
# has none, and that is its premise rather than a gap: the schema is
# `layer_profile: client-only` (ADR-B9-1-001) — no backend layer, no shared/protos, no
# contract of any kind on Forge's side of the line.
#
# The archetype does not manage the server. The identity provider lives in the
# adopter's own information system — a self-hosted Keycloak, an Auth0 subscription —
# and Forge supplies only a corner of config (`oidc-provider.json`) plus a
# standards-conformant client. As long as the server speaks OIDC, it works.
#
# The same boundary applies here. We do not own a server, so there is no server
# contract to generate from: the source of truth is a file the adopter writes and owns
# (ADR-B95-001).
#
# ── THE DESCRIPTOR ───────────────────────────────────────────────────────────
#
#   lib/presentation/<feature>/<feature>.bloc.yaml
#
#     name: Cart                     # PascalCase prefix for every generated class
#     repository: CartRepository     # optional; omit for a bloc with no dependency
#     repository_import: ...         # optional; defaults to the archetype convention
#                                    #   package:<pubspec name>/domain/<feature>/<snake>.dart
#     imports:                       # optional; emitted verbatim into the generated
#       - package:shop/domain/cart/cart_item.dart   # event/state files, for the domain
#                                    #   types your fields refer to
#     events:
#       - ItemAdded: {item: CartItem}
#       - ItemRemoved: {id: String}
#     states:
#       - Initial                    # FIRST entry is the initial state; it must
#       - Loading                    #   declare no fields (see below)
#       - Loaded: {items: List<CartItem>}
#       - Failure: {message: String}
#
# A field-less entry is a bare string; one with fields is a single-key map.
#
# ── WHAT IS GENERATED, AND THE LINE THIS STOPS AT ────────────────────────────
#
# Mechanical: the event hierarchy, the state hierarchy, Equatable props, the
# constructor, the on<Event> registrations, one blocTest per event. All of it copies
# the idiom of the archetype's own lib/presentation/auth/auth_bloc.dart.
#
# NOT mechanical: the handler bodies. auth_bloc's `_onLogin` calls the repository, maps
# the result and emits — business logic no generator can write. Each handler is emitted
# as `throw UnimplementedError(...)`.
#
# THROWING, NOT AN EMPTY BODY. An empty handler emits nothing and the bloc silently
# does nothing: code that looks implemented and is not. This repository already refused
# that shape once, for the offline shell — "a shell whose dependencies are fetched on
# demand fails exactly when it is needed, which is worse than no shell because it looks
# implemented" (pwa.yaml::PWA-RULE-002).
#
# ── THE GENERATED TEST IS A TRIPWIRE ─────────────────────────────────────────
#
# Each blocTest asserts `errors: [isA<UnimplementedError>()]`. It passes while the
# handler is a stub and goes RED the moment the handler is implemented — which is
# exactly when a real assertion is owed. A skipped test, an empty body or
# `expect(true, isTrue)` would be green forever and measure nothing (ADR-B95-003).
#
# Events that declare fields carry a `/* TODO */` in their constructor call, because
# only the adopter can construct their own domain types. Those tests do not compile
# until filled in — deliberately. Fabricating a value would make the suite green on
# data nobody chose.
#
# Usage:
#   forge-gen-bloc.sh --target <dir> --feature <name> [--dry-run] [--force]
#
# Flags:
#   --target <dir>    Project root (required).
#   --feature <name>  Feature directory under lib/presentation/ (required).
#   --dry-run         Print what would be written; mutate nothing.
#   --force           Overwrite existing files instead of refusing.
#   --help, -h        Print this usage and exit 0.
#
# Exit codes: 0 success / 2 usage error / 5 missing tool / 7 precondition not met /
#             8 collision without --force.  (The sibling 0/2/5/7/8 envelope.)

set -euo pipefail

TARGET=""
FEATURE=""
DRY_RUN=0
FORCE=0

err() { echo "forge-gen-bloc: $*" >&2; }

usage() { sed -n '2,80p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

require_tool() { command -v "$1" >/dev/null 2>&1 || { err "missing required tool: $1"; exit 5; }; }

while [ $# -gt 0 ]; do
  case "$1" in
    --target)    TARGET="${2:-}"; shift 2 ;;
    --target=*)  TARGET="${1#*=}"; shift ;;
    --feature)   FEATURE="${2:-}"; shift 2 ;;
    --feature=*) FEATURE="${1#*=}"; shift ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --force)     FORCE=1; shift ;;
    --help|-h)   usage; exit 0 ;;
    *)           err "unknown argument: $1 (try --help)"; exit 2 ;;
  esac
done

[ -n "$TARGET" ]  || { err "--target is required (try --help)"; exit 2; }
[ -n "$FEATURE" ] || { err "--feature is required (try --help)"; exit 2; }
require_tool python3

# ── Phase 0: preflight (FR-B95-007) ──────────────────────────────────────────
[ -d "$TARGET" ] || { err "preflight: target-missing: $TARGET is not a directory"; exit 7; }

PUBSPEC="$TARGET/pubspec.yaml"
[ -f "$PUBSPEC" ] || {
  err "preflight: not-a-flutter-project: $PUBSPEC not found"
  exit 7
}
if ! grep -qE '^[[:space:]]*flutter_bloc:' "$PUBSPEC"; then
  err "preflight: no-flutter-bloc: $PUBSPEC declares no flutter_bloc dependency."
  err "  This generator emits flutter_bloc code; Article VI.3 makes it the only"
  err "  sanctioned state-management library (state-management.yaml)."
  exit 7
fi

DESC="$TARGET/lib/presentation/$FEATURE/$FEATURE.bloc.yaml"
[ -f "$DESC" ] || {
  err "preflight: descriptor-missing: $DESC"
  err "  Write it first — the descriptor is the source of truth, and it is yours."
  err "  Run --help for the format."
  exit 7
}

STAGE="$(mktemp -d -t forge-genbloc-XXXXXX)"
trap 'rm -rf "$STAGE"' EXIT

# ── Phases 1 + 2: parse the descriptor, render the four files ────────────────
DESC="$DESC" FEATURE="$FEATURE" PUBSPEC="$PUBSPEC" STAGE="$STAGE" python3 - <<'PY'
import os, re, sys, yaml

desc_path = os.environ['DESC']
feature   = os.environ['FEATURE']
stage     = os.environ['STAGE']

def die(msg):
    print(f"forge-gen-bloc: preflight: {msg}", file=sys.stderr)
    raise SystemExit(7)

try:
    d = yaml.safe_load(open(desc_path, encoding='utf-8')) or {}
except Exception as exc:
    die(f"descriptor-unparseable: {desc_path}: {exc}")
if not isinstance(d, dict):
    die(f"descriptor-unparseable: {desc_path}: top level is not a mapping")

name = str(d.get('name') or '').strip()
if not name:
    die(f"descriptor-incomplete: {desc_path} declares no `name:`")
if not re.fullmatch(r'[A-Z][A-Za-z0-9]*', name):
    die(f"descriptor-invalid: `name: {name}` must be PascalCase (it prefixes every generated class)")

def normalise(entries, what):
    """[str | {Name: {field: Type}}] -> [(ClassSuffix, [(field, type)])]"""
    if not entries:
        die(f"descriptor-incomplete: {desc_path} declares no `{what}:`")
    out = []
    for e in entries:
        if isinstance(e, str):
            out.append((e, []))
        elif isinstance(e, dict) and len(e) == 1:
            k, v = next(iter(e.items()))
            fields = list((v or {}).items())
            out.append((str(k), [(str(f), str(t)) for f, t in fields]))
        else:
            die(f"descriptor-invalid: each `{what}:` entry is a bare name or a single-key map, got {e!r}")
        if not re.fullmatch(r'[A-Z][A-Za-z0-9]*', out[-1][0]):
            die(f"descriptor-invalid: `{out[-1][0]}` must be PascalCase")
    return out

events = normalise(d.get('events'), 'events')
states = normalise(d.get('states'), 'states')

# The bloc's constructor is `super(const <Name><First>())`, copying AuthBloc's
# `super(const AuthInitial())`. A first state with fields has no zero-argument const
# constructor, so the generated bloc would not compile — refuse here, named, rather
# than emit Dart that dies at `dart analyze`.
if states[0][1]:
    die(f"descriptor-invalid: the first state `{states[0][0]}` declares fields; "
        f"it is the initial state and must be constructible with no arguments")

repo = d.get('repository')
repo = str(repo).strip() if repo else None

# Domain types used by the declared fields live in the adopter's own tree; the
# generator cannot guess where. Without these, any field of a non-primitive type
# produces code that does not compile — which would make the whole generator a
# nuisance rather than a shortcut.
extra_imports = d.get('imports') or []
if not isinstance(extra_imports, list):
    die("descriptor-invalid: `imports:` must be a list of import URIs")
extra_imports = [str(i).strip() for i in extra_imports if str(i).strip()]

def snake(s):
    return re.sub(r'(?<!^)(?=[A-Z])', '_', s).lower()

pkg = ''
for line in open(os.environ['PUBSPEC'], encoding='utf-8'):
    m = re.match(r'^name:\s*([A-Za-z0-9_]+)', line)
    if m:
        pkg = m.group(1)
        break
if not pkg:
    die("cannot derive the package name from pubspec.yaml (no `name:` line)")

repo_import = d.get('repository_import')
if repo and not repo_import:
    # The archetype convention, read off lib/presentation/auth/auth_bloc.dart:
    #   import 'package:<project>/domain/auth/auth_repository.dart';
    repo_import = f"package:{pkg}/domain/{feature}/{snake(repo)}.dart"

HEAD = (f"// GENERATED by bin/forge-gen-bloc.sh from\n"
        f"// lib/presentation/{feature}/{feature}.bloc.yaml\n"
        f"//\n"
        f"// Re-running the generator REFUSES rather than overwriting (exit 8), so your\n"
        f"// edits below are safe. Pass --force only when you mean to discard them.\n")

def hierarchy(base, entries):
    out = [HEAD, "import 'package:equatable/equatable.dart';"]
    out += [f"import '{i}';" for i in extra_imports]
    out += ["",
           f"abstract class {name}{base} extends Equatable {{",
           f"  const {name}{base}();", "  @override",
           "  List<Object?> get props => [];", "}", ""]
    for suffix, fields in entries:
        cls = f"{name}{suffix}"
        out.append(f"class {cls} extends {name}{base} {{")
        if fields:
            args = ", ".join(f"this.{f}" for f, _ in fields)
            out.append(f"  const {cls}({args});")
            out.append("")
            for f, t in fields:
                out.append(f"  final {t} {f};")
            out.append("")
            out.append("  @override")
            out.append(f"  List<Object?> get props => [{', '.join(f for f, _ in fields)}];")
        else:
            out.append(f"  const {cls}();")
        out.append("}")
        out.append("")
    return "\n".join(out)

def ctor_call(cls, fields, const_kw="const "):
    if not fields:
        return f"{const_kw}{cls}()"
    todo = ", ".join(f"/* TODO: {f} ({t}) */" for f, t in fields)
    return f"{const_kw}{cls}({todo})"

# ── the bloc ─────────────────────────────────────────────────────────────────
b = [HEAD, "import 'package:flutter_bloc/flutter_bloc.dart';", ""]
for i in extra_imports:
    b.append(f"import '{i}';")
if repo_import:
    b.append(f"import '{repo_import}';")
b += [f"import '{feature}_event.dart';", f"import '{feature}_state.dart';", "",
      f"class {name}Bloc extends Bloc<{name}Event, {name}State> {{"]
if repo:
    b.append(f"  {name}Bloc({{required {repo} repository}})")
    b.append("      : _repository = repository,")
    b.append(f"        super(const {name}{states[0][0]}()) {{")
else:
    b.append(f"  {name}Bloc() : super(const {name}{states[0][0]}()) {{")
for suffix, _ in events:
    b.append(f"    on<{name}{suffix}>(_on{suffix});")
b.append("  }")
if repo:
    b.append("")
    b.append("  // ignore: unused_field — read by the handlers you are about to write.")
    b.append(f"  final {repo} _repository;")
for suffix, _ in events:
    b.append("")
    b.append(f"  Future<void> _on{suffix}(")
    b.append(f"    {name}{suffix} event,")
    b.append(f"    Emitter<{name}State> emit,")
    b.append("  ) async {")
    b.append(f"    throw UnimplementedError('{name}Bloc._on{suffix} is not implemented');")
    b.append("  }")
b.append("}")
b.append("")

# ── the tripwire test ────────────────────────────────────────────────────────
t = [f"// GENERATED by bin/forge-gen-bloc.sh from",
     f"// lib/presentation/{feature}/{feature}.bloc.yaml",
     "//",
     "// THESE ARE TRIPWIRES, NOT COVERAGE. Each test asserts that its handler still",
     "// throws UnimplementedError. It is green while the handler is a stub and turns",
     "// RED the moment you implement it — which is when you owe a real assertion.",
     "// Counting these as passing tests would be counting an empty suite.",
     "//",
     "// Events that declare fields carry /* TODO */ in their constructor call: only you",
     "// can build your own domain types. Those tests do not compile until you fill them",
     "// in, deliberately — a fabricated value would make the suite green on data nobody",
     "// chose.",
     "",
     "import 'package:bloc_test/bloc_test.dart';",
     "import 'package:flutter_test/flutter_test.dart';",
     "import 'package:mocktail/mocktail.dart';",
     ""]
for i in extra_imports:
    t.append(f"import '{i}';")
if repo_import:
    t.append(f"import '{repo_import}';")
t += [f"import 'package:{pkg}/presentation/{feature}/{feature}_bloc.dart';",
      f"import 'package:{pkg}/presentation/{feature}/{feature}_event.dart';",
      f"import 'package:{pkg}/presentation/{feature}/{feature}_state.dart';",
      ""]
if repo:
    t.append(f"class _Mock{repo} extends Mock implements {repo} {{}}")
    t.append("")
t.append("void main() {")
if repo:
    t.append(f"  late {repo} repository;")
    t.append("")
    t.append("  setUp(() {")
    t.append(f"    repository = _Mock{repo}();")
    t.append("  });")
    t.append("")
build = f"{name}Bloc(repository: repository)" if repo else f"{name}Bloc()"
for suffix, fields in events:
    cls = f"{name}{suffix}"
    t.append(f"  blocTest<{name}Bloc, {name}State>(")
    t.append(f"    '{cls} is not implemented yet',")
    t.append(f"    build: () => {build},")
    t.append(f"    act: (bloc) => bloc.add({ctor_call(cls, fields)}),")
    t.append("    errors: () => [isA<UnimplementedError>()],")
    t.append("  );")
    t.append("")
if t[-1] == "":
    t.pop()
t.append("}")
t.append("")

files = {
    f"lib/presentation/{feature}/{feature}_event.dart": hierarchy("Event", events),
    f"lib/presentation/{feature}/{feature}_state.dart": hierarchy("State", states),
    f"lib/presentation/{feature}/{feature}_bloc.dart": "\n".join(b),
    f"test/presentation/{feature}/{feature}_bloc_test.dart": "\n".join(t),
}
for rel, content in files.items():
    dest = os.path.join(stage, rel)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, 'w', encoding='utf-8') as fh:
        fh.write(content)

print(f"[Phase 1] {len(events)} event(s), {len(states)} state(s)"
      f"{', repository ' + repo if repo else ', no repository'}", file=sys.stderr)
PY

# ── Phase 3: collide, then write (FR-B95-008) ────────────────────────────────
COLLISIONS=()
while IFS= read -r abs; do
  rel="${abs#"$STAGE"/}"
  [ -e "$TARGET/$rel" ] && COLLISIONS+=("$rel")
done < <(find "$STAGE" -type f | sort)

if [ "${#COLLISIONS[@]}" -gt 0 ] && [ "$FORCE" != "1" ]; then
  err "${#COLLISIONS[@]} file(s) already exist in the target:"
  printf '  %s\n' "${COLLISIONS[@]}" >&2
  err "  Re-run with --force to overwrite — this DISCARDS the handlers you wrote."
  exit 8
fi

COUNT=0
while IFS= read -r abs; do
  rel="${abs#"$STAGE"/}"
  if [ "$DRY_RUN" = "1" ]; then
    echo "    [write] $rel"
  else
    mkdir -p "$(dirname "$TARGET/$rel")"
    cp "$abs" "$TARGET/$rel"
  fi
  COUNT=$((COUNT + 1))
done < <(find "$STAGE" -type f | sort)

if [ "$DRY_RUN" = "1" ]; then
  echo "[Phase 2] dry-run: $COUNT file(s) would be written"
  exit 0
fi

echo "[Phase 2] wrote $COUNT file(s)"
echo ""
echo "Next steps :"
echo "  implement each handler in lib/presentation/$FEATURE/${FEATURE}_bloc.dart"
echo "  its tripwire test goes RED as you do — replace it with a real assertion"
echo "  fill the /* TODO */ event payloads in test/presentation/$FEATURE/"
