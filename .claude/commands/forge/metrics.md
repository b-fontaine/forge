# /forge:metrics — Development Velocity Metrics

## Purpose
Calculate and display development velocity metrics across all changes (active and archived).

## Process

1. Scan all directories in `.forge/changes/`
2. For each change, read `.forge.yaml`:
   - Extract `status` and `timeline` entries
   - Calculate duration between consecutive timeline entries
3. Aggregate metrics:
   a. Per-phase average duration (days between status transitions)
   b. Total cycle time (created to archived) for completed changes
   c. Pipeline distribution (count of changes per current status)
   d. Bottleneck identification (phase with longest average duration)
4. If no archived changes exist, show only pipeline state
5. If timeline data is missing (older changes), mark as "N/A"

## Output

```
FORGE METRICS
=============
Generated: <date>

Pipeline State:
  Proposed:      N changes
  Specified:     N changes
  Designed:      N changes
  Planned:       N changes
  Implemented:   N changes
  Archived:      N changes (total completed)

Cycle Time (archived changes only):
  Average total cycle:       X.X days
  Fastest:                   X.X days (<name>)
  Slowest:                   X.X days (<name>)

Phase Breakdown (average days):
  Proposed → Specified:      X.X days
  Specified → Designed:      X.X days
  Designed → Planned:        X.X days
  Planned → Implemented:     X.X days   ← bottleneck
  Implemented → Archived:    X.X days

Throughput:
  Changes completed this week:   N
  Changes completed this month:  N
  Average:                       X.X changes/week
```

## Data Requirements
- Requires `timeline` section in `.forge.yaml` per change (added in template update)
- Each lifecycle command (`propose`, `specify`, `design`, `plan`, `implement`, `archive`) records its timestamp
- Older changes without timestamps show "N/A" for timing data

## When to Use
- Sprint retrospectives — identify process bottlenecks
- Status reports — show throughput and pipeline health
- On-demand — anytime you want to check velocity
