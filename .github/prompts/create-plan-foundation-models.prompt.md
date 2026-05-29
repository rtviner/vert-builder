# Model Generation Prompt

## Instructions

- Run the rails migration generator command in the devcontainer (`devcontainer exec --workspace-folder . bin/rails generate model {{name}}`)for each model that needs to be created, include the model name as `{{name}}`
- create a new branch (git checkout -b) for each model creation with a descriptive name (e.g. `git checkout -b "create-plan-model"`)
- define columns, types, and default values directly in the model migration file for the relevant columns (e.g. `t.integer :baseline_vertical_distance, null: false, default: 0`), and add any necessary indexes (e.g. `add_index :weeks, [:plan_id, :week_number], unique: true`)
- use attr_accessor and instance variables to avoid using self in the model methods and validations
- add validations, and any scopes or methods described below to the model files at the appropriate time (the Week must be created to add the current_week scope to the Plan model)
- update generated tests for each model, to cover any public methods, custom validations, anything at risk of regression.
- use `just generate_migration name_of_migration` to generate a new migration file for any updates needed to existing models (e.g. adding associations or columns)
- run the migrations using `just migrate` after all model files have been created, updated, and approved
- Maintain the hierarchy: ensure the associations reflect this hierarchy (User has_many Plans, Plan belongs_to User, Plan has_many Weeks, Week belongs_to Plan, Week has_many Days, Day belongs_to Week)

## Models

###:`Plan`
**Columns:**

- user_id: references, null: false
- baseline_vertical_distance: integer, cannot be null, default: 0
- baseline_duration: integer, cannot be null, default: 0
- goal_vertical_distance: integer, cannot be null, default: 0
- goal_duration: integer, null: true, default: 0
- start_date: date, null: true
- end_date: date, null: true
- completed_date: date, null: true
- flexible_end_date: boolean, null: false, default: false
- recovery_pattern: integer (enum), null: false
  # 0 = every_other, 1 = every_third, 2 = every_fourth
- vertical_build_percentage: integer, null: false, default: 10
  # the % increase in vertical distance per build week (5-15%), stored so it can be adjusted
- status: integer (enum), null: false, default: 0
  # 0 = planned, 1 = active, 2 = completed, 3 = abandoned
  **Associations:**
- belongs_to :user
  **constants:**
- MAX_BUILD_PERCENTAGE = 15
  **Validations:**
- validates :baseline_vertical_distance, baseline_duration, goal_vertical_distance, recovery_pattern, vertical_build_percentage, :status, presence: true
- validates :vertical_build_percentage, numericality: { greater_than_or_equal_to: 5, less_than_or_equal_to: MAX_BUILD_PERCENTAGE }
- validates: goal_vertical_distance, numericality: { greater_than: :baseline_vertical_distance }
- validates: end_date_after_start_date, if: -> { start_date.present? && end_date.present? }

---

###: `Week`
**Columns:**

- plan_id: references, null: false
- week_number: integer, null: false
  # position in the plan (week 1, 2, 3...)
- is_recovery: boolean, null: false, default: false
  # drives the 40-60% reduction logic
- status: integer (enum), null: false, default: 0
  # 0 = upcoming, 1 = in_progress, 2 = completed
- start_date: date, null: false
- end_date: date, null: false
- planned_duration: integer, null: false, default: 0
- completed_duration: integer, null: false, default: 0
- planned_vertical_distance: integer, null: false, default: 0
- completed_vertical_distance: integer, null: false, default: 0
  **Associations:**
- belongs_to :Plan
  **Validations:**
- validates :planned_vertical_distance, planned_duration, :start_date, :end_date, :week_number, :status, presence: true
- validates: end_date_after_start_date
- validates: week_number, numericality: { greater_than: 0 }, uniqueness: { scope: :plan_id }
- validates: completed_vertical_distance, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: -> { status == "completed" }
- validates: completed_duration, presence: true,numericality: { greater_than_or_equal_to: 0 }, if: -> { status == "completed" }
  **Scopes:**
- completed_weeks: -> { where(status: :completed) }
  **indexes:**
- unique index on [plan_id, week_number]

## Updates for Plan model once Week model is created:

**Plan Scopes**

- current_week: weeks.where(status: in_progress).first
  **Plan Methods:**
- progress_percentage: calculate based on completed weeks and total weeks of the plan

---

### `Day`

**Columns:**

- week_id: references, null: false
- planned_vertical_distance: integer, cannot be null, default: 0
- completed_vertical_distance: integer, null: true, default: 0
- completed_date: date, null: true
- strava_activity_id: string, null: true
- status: integer (enum), null: false, default: 0
  # 0 = upcoming, 1 = completed, 2 = skipped
  **Associations:**
- belongs_to :week
  **Validations:**
- validates: planned_vertial_distance, status, presence: true
  **Methods:**
- complete!(completed_date: Date.today)
  # sets status to completed, sets completed_date
  # triggers week completion check
- skip!
  # sets status to skipped
  # marks updated_at date
  # triggers week completion check

## Updates to Week model once Day model is created:

**Week Methods:**

- complete!(completed_date: Date.today)
  # sets status to completed, when the end_date is in the past, checks if any days in week are not marked completed and sets them to 'skipped'
- log_week_progress
  # user can update the completed_vertical_distance and completed_duration, calls complete! if it has not been called yet and end_date is in the past, otherwise just updates the completed_vertical_distance and completed_duration for the week without changing the status

### `User` (already exists — update where neccessary)

**Existing columns:** id, email_address, password_digest, created_at, updated_at
**Associations to add:** once the Plan model is created, add `has_many :plans` association to the User model

- has_many :plans
  **Methods**
- average_weekly_vertical_distance:
  # if fewer than 4 completed weeks exist across all plans, fall back to the most recent plan's baseline_vertical_distance
  # otherwise average the last 4 completed weeks vertical distance
- average_weekly_duration:
  # if fewer than 4 completed weeks exist across all plans, fall back to the most recent plan's baseline_duration,
  # otherwise average the last 4 completed weeks duration

---
