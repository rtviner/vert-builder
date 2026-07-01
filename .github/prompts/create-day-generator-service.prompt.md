
# Prompt 2 — Day Generation

## Context
- Service object lives at `app/services/day_generator.rb`
- The plan generator service skeleton already exists at `app/services/plan_generator.rb` with stubbed methods for `build_weeks` which will call `build_days(week)` for each week
- `build_weeks` will be implemented in Prompt 3
- This prompt covers **only** the day generation layer
- This method is called assuming a fully built week object with `planned_vertical_distance` and `week_type` already set
- Models are already implemented

## Constraints
- Do not implement `build_week`, `build_weeks`, or any plan-level logic
- Do not modify the Day or Week schema
- `build_days` must return an array of 7 Day objects (unsaved or saved — match skeleton convention)
- Raise `ArgumentError` for unknown `week_type` values

---

## Week Object (given, do not build)

The `week` object passed into `build_days` already has these attributes set:

```ruby
week.planned_vertical_distance  # integer, total vert for the week
week.is_recovery                # boolean
week.week_type                  # string: "progression", "recovery", "taper", "goal"
```

---

## Day Generation Rules
- All generated days default to `status: 0` (upcoming)
- All `planned_vertical_distance` values must be **rounded to the nearest 10**
- Nullable fields are not set during generation

---

## `build_days(week)` — Entry Point

Dispatch to the correct builder based on `week.week_type`:

```
"progression" → build_progression_days(week)
"recovery"    → build_recovery_days(week)
"taper"       → build_taper_days(week)
"goal"        → build_goal_days(week)
```

Returns an array of 7 Day objects associated with the week.

---

## Week Type Rules

### Progression Week — `build_progression_days(week)`

```
week_vert             = week.planned_vertical_distance
total_hard_percentage = rand(0.75..0.80)
long_day              = week_vert * 0.35
hard_day_2            = week_vert * rand(0.20..0.25)
hard_day_3            = week_vert * (total_hard_percentage - 0.35 - hard_day_2_percentage)
easy_days_total       = week_vert * (1 - total_hard_percentage)
```

**Normal case** — `easy_days_total >= (4 * 90)`:
- 4 easy days, randomized
- Each easy day: min 90ft, max 15% of week_vert
- Easy days must sum to `easy_days_total`

**Fallback case** — `easy_days_total < (4 * 90)`:
- 1 easy day = 0 vert
- 3 easy days = `easy_days_total / 3` each
- 90ft minimum does not apply

**Day array ordering:**
```
day_1 = easy
day_2 = hard (hard_day_2 or hard_day_3, interchangeable)
day_3 = easy
day_4 = long_day
day_5 = easy
day_6 = hard (the other hard day)
day_7 = easy
```

---
### Recovery & Taper Weeks — Shared Distribution

- Both recovery and taper weeks use identical distribution math and normal/fallback logic. 
- Extract this into a private method:

```
build_recovery_distribution(week)
```
**returns** { long_day:, medium_day:, remaining_5: [] }
**Distribution math:**
```
week_vert              = week.planned_vertical_distance
long_day               = week_vert * 0.40
medium_day             = week_vert * 0.20
remaining_5_days_total = week_vert * 0.40
Normal case — remaining_5_days_total / 5 >= 90:
```
**Normal case** — `remaining_5_days_total / 5 >= 90`:
- 5 remaining days share `remaining_5_days_total`
- 1 of the 5 must be between 90–100ft
- Each of the remaining 4: capped at 15% of week_vert
- Values are randomized with variation, must sum to `remaining_5_days_total`

**Fallback case** — `remaining_5_days_total / 5 < 90`:
- 1 day = 0 vert
- Remaining 4 days share `remaining_5_days_total`
- Apply variation of 50–100ft between days if possible
- If not possible — divide evenly, no variation
- 90–100ft requirement is dropped

### Recovery Week — `build_recovery_days(week)`

Calls `build_recovery_distribution(week)`, then applies ordering:

**Day array ordering:**
- All 7 days are shuffled randomly each time
- `long_day` and `medium_day` must not be adjacent
- If a shuffle produces them adjacent, swap `medium_day` with the nearest non-adjacent day

---

### Taper Week — `build_taper_days(week)`

Calls `build_recovery_distribution(week)`, then applies fixed ordering:

**Day array ordering:**
```
day_1 = long_day
day_2 = easy day (from remaining 5)
day_3 = medium_day
days_4–7 = remaining 4 days, randomized
```

---

### Goal/Peak Week — `build_goal_days(week)`

```
week_vert                  = week.planned_vertical_distance
goal_vertical_distance     = @plan.goal_vertical_distance
recovery_vertical_distance = week_vert - goal_vertical_distance
long_day                   = recovery_vertical_distance * 0.40
medium_day                 = recovery_vertical_distance * 0.20
goal_day                   = goal_vertical_distance
remaining_4_days_total     = recovery_vertical_distance * 0.40
```

Method signature stays `build_goal_days(week)` — access `@plan.goal_vertical_distance` directly as the service already holds `@plan` as an instance variable.

**Normal case** — `remaining_4_days_total / 4 >= 90`:
- 4 remaining days share `remaining_4_days_total`
- 1 of the 4 must be between 90–100ft
- Each of the remaining 3: capped at 15% of `recovery_vertical_distance`
- Randomized with variation, must sum to `remaining_4_days_total`

**Fallback case** — `remaining_4_days_total / 4 < 90`:
- 1 day = 0 vert
- Remaining 3 days share `remaining_4_days_total`
- Variation of 50–100ft between days if possible
- If not possible — divide evenly, no variation
- 90–100ft requirement dropped

**Day array ordering:**
```
day_1 = long_day
day_2 = remaining day (random)
day_3 = medium_day
day_4 = remaining day (random)
day_5 = remaining day (random)
day_6 = goal_day
day_7 = remaining day (random)
```

---

## Shared Helpers to Implement

- `round_to_nearest_10(value)` — rounds any float to nearest integer multiple of 10
- `randomize_days_with_sum(total:, count:, min:, max:)` — distributes `total` across `count` values, each between `min` and `max`, randomized, summing exactly to `total` after rounding
- `apply_variation(values:, range:)` — adds variation within a range across an array of values while preserving their sum
- `build_recovery_distribution(week)` — shared distribution logic for recovery and taper weeks, returns `{ long_day:, medium_day:, remaining_5: [] }`

---

## Rounding Rules

- Every `planned_vertical_distance` stored on a Day must be rounded to the nearest 10
- After rounding all days, adjust `day_2` to absorb any rounding remainder so the week's days sum exactly to `week.planned_vertical_distance`
- This applies to all week types — `day_2` is always an easy or remaining day, never a hard, long, medium, or goal day

---

## Tests to Write

Use Minitest and fixtures. Use mock objects for week and @plan where needed.  Day fixtures represent fully built Day records with planned_vertical_distance set — use them to assert against expected output.

### Progression Week Tests
- [ ] Day count is always 7
- [ ] Hard days sum to `total_hard_percentage` of week vert (within rounding tolerance of 10)
- [ ] Easy days sum to remainder (within rounding tolerance of 10)
- [ ] All day verts are multiples of 10
- [ ] Normal case: no easy day below 90ft or above 15% of week vert
- [ ] Fallback case: use `week_vert: 1400` to guarantee trigger — expect 1 zero day and 3 equal days
- [ ] Day ordering: positions 1, 3, 5, 7 are easy; position 4 is the long day; positions 2 and 6 are hard

### Recovery Week Tests
- [ ] Day count is always 7
- [ ] `long_day` = 40% of week vert (within rounding tolerance of 10)
- [ ] `medium_day` = 20% of week vert (within rounding tolerance of 10)
- [ ] Remaining 5 days sum to 40% of week vert (within rounding tolerance of 10)
- [ ] Normal case: exactly 1 remaining day between 90–100ft
- [ ] Normal case: no remaining day exceeds 15% of week vert
- [ ] Fallback case: exactly 1 zero day
- [ ] `long_day` and `medium_day` are never adjacent in any shuffle

### Taper Week Tests
- [ ] Same vert distribution as recovery week (delegates to build_recovery_distribution)
- [ ] Day 1 is the long day
- [ ] Day 2 is an easy/remaining day (not medium, not long)
- [ ] Day 3 is the medium day

### Goal/Peak Week Tests
-  Mock @plan.goal_vertical_distance to return a fixed value
- [ ] Day count is always 7
- [ ] Day 6 equals `goal_vertical_distance` (rounded to nearest 10)
- [ ] `long_day` and `medium_day` derived from `recovery_vertical_distance`, not `week_vert`
- [ ] Day 1 is long, day 3 is medium, day 6 is goal
- [ ] Normal case: exactly 1 remaining day between 90–100ft
- [ ] Fallback case: exactly 1 zero day among the 4 remaining

### Shared Distribution Tests — `build_recovery_distribution`
- [ ] Returns correct long_day, medium_day, and remaining_5 keys
- [ ] Normal case: remaining_5 contains exactly 1 value between 90–100ft
- [ ] Normal case: no value in remaining_5 exceeds 15% of week_vert
- [ ] Fallback case: exactly 1 zero value in remaining_5
- [ ] Sum of long_day + medium_day + remaining_5 equals week_vert (within rounding tolerance of 10)

### Cross-cutting
- [ ] All `planned_vertical_distance` values are multiples of 10 across all week types
- [ ] Sum of all 7 days equals `week.planned_vertical_distance` for all week types