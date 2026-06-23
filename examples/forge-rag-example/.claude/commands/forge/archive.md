# /forge:archive <name> — Archive Completed Change

## Purpose
Merge delta specs into the main spec files and mark change as complete.

## Pre-condition Check
Verify `.forge.yaml` shows review has passed (or user explicitly confirms).

## Delta Merge Process

For each delta section in `.forge/changes/<name>/specs.md`:

### ADDED Requirements → APPEND to target spec file
Find the target spec file in `.forge/specs/` (create if doesn't exist).
Append the new requirements with their IDs.

### MODIFIED Requirements → REPLACE in target spec file
Find the original requirement by ID.
Replace with new version.
Add comment: `<!-- Modified in <name> change, <date> -->`
Keep "Previously:" text commented out for history.

### REMOVED Requirements → MARK DEPRECATED
Find requirement by ID.
Add: `~~[FR-XXX]~~ **DEPRECATED** in <name> change, <date>. Reason: [reason]`

## Post-Archive
1. Update `.forge.yaml` status: archived
   Record timestamp: `timeline.archived: <current ISO-8601 date>`
2. Move completed tasks to archived section
3. Update `.forge/product/roadmap.md` if milestone completed
4. Suggest: "Preview changes with `/forge:diff <name>` before archiving"
5. Invoke **Calliope** (Technical Writer) for changelog and documentation updates

## Summary
```
✅ Change '<name>' archived

Specs updated:
- [N] requirements added
- [N] requirements modified  
- [N] requirements deprecated

Change data preserved in: .forge/changes/<name>/
Active spec updated: .forge/specs/[feature].md
```
