# Model Generation Prompt

## Context
- Rails 8 API-only app
- PostgreSQL database
- Authentication via Rails 8 generator (User and Session models already exist)
- Parent model (User) already exists and may need updating

## Instructions
- Run the rails migration generator command (`rails g model`)for each model that needs to be created or updated 
- include the attributes with associations, and types in the command to generate the model files with the correct columns and types
- create a new branch (git checkout -b) for each model creation with a descriptive name (e.g. `create-plan-model`) 
- define enums, default values directly in the model migration file for the relevant columns
- add validations, and any scopes or methods described below to the model files
- update generated tests for each model, to cover any public methods, custom validations, anything at risk of regression.
- Flag any changes needed to existing models
- run the migrations using `just migrate` after all model files have been created, updated, and approved
- ask user to review the generated code and commit the changes with a descriptive commit message (e.g. `Add Plan model with associations and validations`) before moving on to the next model
- Maintain the hierarchy: Parent → Child → Grandchild → Great grandchild but use the actual model names in the code (User → Plan → Week → Day) and ensure the associations reflect this hierarchy (User has_many Plans, Plan belongs_to User, Plan has_many Weeks, Week belongs_to Plan, Week has_many Days, Day belongs_to Week)


## Models

### Parent: `User` (already exists — update only if neccessary)
**Existing columns:** id, email_address, password_digest, created_at, updated_at
**Associations to add:**
- has_many :children
**Methods**
- average_weekly_vertical_distance:
  # if fewer than 4 completed weeks exist across all plans, fall back to the most recent plan's baseline_vertical_distance
  # otherwise average the last 4 completed weeks vertical distance
- average_weekly_duration: 
  # if fewer than 4 completed weeks exist across all plans, fall back to the most recent plan's baseline_duration,
  # otherwise average the last 4 completed weeks duration

---

### Child: `Plan`
**Columns:**
- parent_id: references, null: false
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
- belongs_to :parent
- has_many :grandchildren
**constants:**
- MAX_BUILD_PERCENTAGE = 15
**Validations:**
- validates :baseline_vertical_distance, baseline_duration, goal_vertical_distance, recovery_pattern, vertical_build_percentage, :status, presence: true
- validates :vertical_build_percentage, numericality: { greater_than_or_equal_to: 5, less_than_or_equal_to: MAX_BUILD_PERCENTAGE }
- validates: goal_vertical_distance, numericality: { greater_than: :baseline_vertical_distance }
- validates: end_date_after_start_date, if: -> { start_date.present? && end_date.present? }
**Scopes**
- current_week: weeks.where(status: in_progress).first
**Methods:** 
- progress_percentage: calculate based on completed weeks and total weeks of the plan

---

### Grandchild: `Week`
**Columns:**
- child_id: references, null: false
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
- belongs_to :child
- has_many :great_grandchildren
**Validations:**
- validates :planned_vertical_distance, planned_duration, :start_date, :end_date, :week_number, :status, presence: true
- validates: end_date_after_start_date
- validates: week_number, numericality: { greater_than: 0 }, uniqueness: { scope: :plan_id }
- validates: completed_vertical_distance, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: -> { status == "completed" }
- validates: completed_duration, presence: true,numericality: { greater_than_or_equal_to: 0 }, if: -> { status == "completed" }
**Scopes:**
- completed_weeks: -> { where(status: :completed) }
**Methods:**
- complete!(completed_date: Date.today)
  # sets status to completed, when the end_date is in the past, checks if any days in week are not marked completed and sets them to 'skipped'
- log_week_progress
  # user can update the completed_vertical_distance and completed_duration, calls complete! if it has not been called yet and end_date is in the past, otherwise just updates the completed_vertical_distance and completed_duration for the week without changing the status
**indexes:**
- unique index on [plan_id, week_number]

---


### Great grandchild: `Day`
**Columns:**
- grandchild_id: references, null: false
- planned_vertical_distance: integer, cannot be null, default: 0
- completed_vertical_distance: integer, null: true, default: 0
- completed_date: date, null: true
- strava_activity_id: string, null: true
- status: integer (enum), null: false, default: 0
  # 0 = upcoming, 1 = completed, 2 = skipped
**Associations:**
- belongs_to :grandchild
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






