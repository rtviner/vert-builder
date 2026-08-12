# VertBuilder Public API Documentation

## 1. Overview

- Base URL: `https://api.yourapp.com`
- API version prefix: `/api/v1`
- Authentication model: Bearer token
  - Successful registration or login returns an auth token in the response body.
  - Subsequent requests must send the token in the `Authorization` header as `Bearer <token>`.
- Standard response format:
  - Success: JSON body containing the requested resource or action result.
  - Error: JSON body containing an `error` object with status, message, and optional details.

### Standard error response structure

```json
{
  "error": {
    "status": 422,
    "message": "Validation failed",
    "errors": ["...message..."]
  }
}
```

Some endpoints return simpler error shapes, for example:

```json
{ "error": "Invalid email address or password" }
```

## 2. Register a new user

### Endpoint

- `POST /api/v1/registrations`

### Request body

| Field                         | Type   | Required | Notes                                                                                         |
| ----------------------------- | ------ | -------- | --------------------------------------------------------------------------------------------- |
| `user[email_address]`         | string | yes      | Must be a valid email format. Saved lowercase and trimmed.                                    |
| `user[password]`              | string | yes      | No explicit minimum length in code; Password length should be less than or equal to 72 bytes. |
| `user[password_confirmation]` | string | yes      | Must match `password`.                                                                        |

### Validation rules

- `email_address` must be present
- `email_address` must be unique (case-insensitive)
- `email_address` must match standard email format (`URI::MailTo::EMAIL_REGEXP`)
- `password` must be present
- `password_confirmation` must match `password`

### Authentication behavior

- Successful registration creates a new session and returns a bearer token.
- Use that token in `Authorization: Bearer <token>` for subsequent authenticated requests.

### Example request

```bash
curl -X POST https://api.yourapp.com/api/v1/registrations \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email_address": "test@example.com",
      "password": "password",
      "password_confirmation": "password"
    }
  }'
```

### Example success response

Status: `201 Created`

```json
{
  "token": "<auth_token>",
  "user": {
    "id": 123,
    "email_address": "test@example.com",
    "created_at": "2026-08-03T00:00:00.000Z",
    "updated_at": "2026-08-03T00:00:00.000Z"
  }
}
```

### Example error responses

- Duplicate email:

Status: `422 Unprocessable Entity` or `422`/`422` depending on validation path

```json
{
  "errors": ["Email address has already been taken"]
}
```

- Invalid email format:

Status: `422 Unprocessable Entity`

```json
{
  "errors": ["Email address is invalid"]
}
```

- Password confirmation mismatch:

Status: `422 Unprocessable Entity`

```json
{
  "errors": ["Password confirmation doesn't match Password"]
}
```

- Duplicate email on unique constraint failure:

Status: `422 Unprocessable Content`

```json
{
  "error": ["There was a problem creating your account"]
}
```

## 3. Update password

### Endpoint

- `PATCH /api/v1/passwords/:id`

### Auth requirement

- Requires authentication via `Authorization: Bearer <token>`.
- The `:id` path value is the session resource ID, but authenticated requests are validated by bearer token.

### Request body

| Field                       | Type   | Required | Notes                                 |
| --------------------------- | ------ | -------- | ------------------------------------- |
| `current_password`          | string | yes      | Required to confirm current password. |
| `new_password`              | string | yes      | New password value.                   |
| `new_password_confirmation` | string | yes      | Must match `new_password`.            |

### Behavior

- Verifies the current password for the authenticated user.
- If valid, updates the password and destroys the current session token.
- The client must log in again after a successful password update.

### Example request

```bash
curl -X PATCH https://api.yourapp.com/api/v1/passwords/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <auth_token>" \
  -d '{
    "current_password": "password",
    "new_password": "newpassword",
    "new_password_confirmation": "newpassword"
  }'
```

### Example success response

Status: `200 OK`

```json
{
  "message": "Password updated successfully"
}
```

### Example error responses

- Wrong current password:

Status: `401 Unauthorized`

```json
{
  "error": "Current password is incorrect"
}
```

- Password confirmation mismatch:

Status: `422 Unprocessable Entity`

```json
{
  "errors": ["Password confirmation doesn't match Password"]
}
```

## 4. Create a new plan

### Endpoint

- `POST /api/v1/plans`

### Auth requirement

- Requires authentication via `Authorization: Bearer <token>`.

### Request body

| Field                              | Type    | Required | Notes                                                                                                                |
| ---------------------------------- | ------- | -------- | -------------------------------------------------------------------------------------------------------------------- |
| `plan[baseline_vertical_distance]` | integer | yes      | Must be >= 1000.                                                                                                     |
| `plan[baseline_duration]`          | integer | yes      | Base duration in minutes (presence required).                                                                        |
| `plan[goal_vertical_distance]`     | integer | yes      | Must be greater than `baseline_vertical_distance`.                                                                   |
| `plan[goal_duration]`              | integer | optional | Can be omitted.                                                                                                      |
| `plan[recovery_pattern]`           | string  | optional | Allowed values: `every_other`, `every_third`, `every_fourth`. Defaults to `every_other` if omitted by model default. |
| `plan[vertical_build_percentage]`  | integer | yes      | Must be >= 5 and < 15. Defaults to `10`.                                                                             |
| `plan[flexible_end_date]`          | boolean | NA       | Defaults to `true`                                                                                                   |
| `plan[start_date]`                 | date    | optional | Not required for plan creation                                                                                       |
| `plan[end_date]`                   | date    | optional | Required if `start_date` is present.                                                                                 |

### Server-controlled/read-only fields (do not send)

| Field                                                                        | Notes                                   |
| ---------------------------------------------------------------------------- | --------------------------------------- |
| `id`                                                                         | Assigned by server.                     |
| `flexible_end_date`                                                          | Not functional in code yet.             |
| `status`                                                                     | Managed by server; starts as `planned`. |
| `created_at`                                                                 | Assigned by server.                     |
| `updated_at`                                                                 | Assigned by server.                     |
| `week_count`, `current_week_number`, `progress_percentage`, `completed_date` | Returned in responses only.             |

### Validation constraints

- `baseline_vertical_distance`: integer >= 1000
- `baseline_duration`: present
- `goal_vertical_distance`: integer greater than `baseline_vertical_distance`
- `vertical_build_percentage`: integer >= 5 and < 15
- `recovery_pattern`: one of `every_other`, `every_third`, `every_fourth`
- `flexible_end_date`: only true is valid currently
- If `start_date` and `end_date` are supplied, `end_date` must be after `start_date`

### Example request

```bash
curl -X POST https://api.yourapp.com/api/v1/plans \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <auth_token>" \
  -d '{
    "plan": {
      "baseline_vertical_distance": 1624,
      "baseline_duration": 180,
      "goal_vertical_distance": 3300,
      "vertical_build_percentage": 10,
      "recovery_pattern": "every_fourth",
      "start_date": "2026-08-03",
      "end_date": "2026-10-26"
    }
  }'
```

### Example success response

Status: `201 Created`

```json
{
  "id": 42,
  "baseline_vertical_distance": 1624,
  "baseline_duration": 180,
  "goal_vertical_distance": 3300,
  "recovery_pattern": "every_fourth",
  "vertical_build_percentage": 10,
  "flexible_end_date": true,
  "start_date": "2026-08-03",
  "end_date": "2026-10-26",
  "status": "planned",
  "created_at": "2026-08-03T00:00:00.000Z",
  "updated_at": "2026-08-03T00:00:00.000Z"
}
```

### Example validation error response

Status: `422 Unprocessable Entity`

```json
{
  "errors": [
    "Baseline vertical distance can't be blank",
    "Goal vertical distance must be greater than baseline vertical distance"
  ]
}
```

## 5. List all plans

### Endpoint

- `GET /api/v1/plans`

### Auth requirement

- Requires authentication via `Authorization: Bearer <token>`.

### Query parameters

| Name     | Type   | Required | Default | Notes                                                                                  |
| -------- | ------ | -------- | ------- | -------------------------------------------------------------------------------------- |
| `status` | string | optional | none    | Filter plans by status. Allowed values: `planned`, `active`, `completed`, `abandoned`. |

### Example request

```bash
curl -X GET "https://api.yourapp.com/api/v1/plans" \
  -H "Authorization: Bearer <auth_token>"
```

### Example response

Status: `200 OK`

```json
[
  {
    "id": 12,
    "status": "active",
    "recovery_pattern": "every_fourth",
    "baseline_vertical_distance": 1300,
    "goal_vertical_distance": 3300,
    "vertical_build_percentage": 10,
    "start_date": "2026-08-03",
    "end_date": "2026-10-26",
    "created_at": "2026-08-03T00:00:00.000Z",
    "week_count": 12,
    "current_week_number": 3,
    "progress_percentage": 25
  },
  {
    "id": 13,
    "status": "planned",
    "recovery_pattern": "every_other",
    "baseline_vertical_distance": 1000,
    "goal_vertical_distance": 2500,
    "vertical_build_percentage": 10,
    "start_date": null,
    "end_date": null,
    "created_at": "2026-08-03T00:00:00.000Z",
    "week_count": 10,
    "current_week_number": null,
    "progress_percentage": 0
  }
]
```

### Error response for invalid `status`

Status: `422 Unprocessable Entity`

```json
{
  "error": {
    "status": 422,
    "message": "Validation failed",
    "errors": ["status must be one of: planned, active, completed, abandoned"]
  }
}
```

## 6. View a single plan by ID

### Endpoint

- `GET /api/v1/plans/:id`

### Auth requirement

- Requires authentication via `Authorization: Bearer <token>`.

### Path parameter

| Name | Type    | Required | Notes                             |
| ---- | ------- | -------- | --------------------------------- |
| `id` | integer | yes      | Plan record ID from the database. |

### Example request

```bash
curl -X GET https://api.yourapp.com/api/v1/plans/42 \
  -H "Authorization: Bearer <auth_token>"
```

### Example success response

Status: `200 OK`

```json
{
  "id": 42,
  "status": "active",
  "recovery_pattern": "every_fourth",
  "baseline_vertical_distance": 1624,
  "goal_vertical_distance": 3300,
  "vertical_build_percentage": 10,
  "start_date": "2026-08-03",
  "end_date": "2026-10-26",
  "created_at": "2026-08-03T00:00:00.000Z",
  "completed_date": null,
  "weeks": [
    {
      "id": 101,
      "week_number": 1,
      "week_type": "progression",
      "status": "completed",
      "start_date": "2026-08-03",
      "end_date": "2026-08-09",
      "days": [
        {
          "id": 1001,
          "position": 1,
          "planned_vertical_distance": 300,
          "status": "completed"
        },
        {
          "id": 1002,
          "position": 2,
          "planned_vertical_distance": 300,
          "status": "completed"
        }
      ]
    }
  ]
}
```

### Example error responses

- Plan not found or not owned by user:

Status: `404 Not Found`

```json
{
  "error": {
    "status": 404,
    "message": "Resource not found",
    "detail": "Couldn't find Plan"
  }
}
```

## 7. Activate a plan

Adds dates to a plan if it was not created with a start date

### Endpoint

- `PATCH /api/v1/plans/:id/activate`

### Auth requirement

- Requires authentication via `Authorization: Bearer <token>`.

### Path parameter

| Name | Type    | Required | Notes           |
| ---- | ------- | -------- | --------------- |
| `id` | integer | yes      | Plan record ID. |

### Request body

| Field        | Type | Required | Notes                                                                                                                                                                                        |
| ------------ | ---- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `start_date` | date | optional | Must be supplied if plan has no stored `start_date`. If supplied, the plan start date is updated and each week date range is recalculated. If omitted, the stored plan `start_date` is used. |

### Behavior

- Transitions the plan status from `planned` to `active`.
- If `start_date` is provided, the plan and its weeks receive new calculated start/end dates.
- No explicit deactivation of other plans is present in the code.

### Example request

```bash
curl -X PATCH https://api.yourapp.com/api/v1/plans/42/activate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <auth_token>" \
  -d '{
    "start_date": "2026-08-03"
  }'
```

### Example success response

Status: `200 OK`

```json
{
  "id": 42,
  "status": "active",
  "recovery_pattern": "every_fourth",
  "baseline_vertical_distance": 1624,
  "goal_vertical_distance": 3300,
  "vertical_build_percentage": 10,
  "start_date": "2026-08-03",
  "end_date": "2026-10-26",
  "created_at": "2026-08-03T00:00:00.000Z",
  "completed_date": null,
  "weeks": [
    {
      "id": 101,
      "week_number": 1,
      "week_type": "progression",
      "status": "planned",
      "start_date": "2026-08-03",
      "end_date": "2026-08-09",
      "days": [
        {
          "id": 1001,
          "position": 1,
          "planned_vertical_distance": 300,
          "status": "upcoming"
        }
      ]
    }
  ]
}
```

### Example error responses

- Missing or invalid `start_date`:

Status: `400 Bad Request`

```json
{
  "error": {
    "status": 400,
    "message": "Bad request",
    "detail": "start_date is required"
  }
}
```

- Already active plan:

Status: `422 Unprocessable Entity`

```json
{
  "error": {
    "status": 422,
    "message": "Validation failed",
    "errors": ["Event 'activate' cannot transition from 'active'."]
  }
}
```

- Plan belongs to another user:

Status: `404 Not Found`

```json
{
  "error": {
    "status": 404,
    "message": "Resource not found",
    "detail": "Couldn't find Plan"
  }
}
```

## 8. Export a plan as CSV

### Endpoint

- `GET /api/v1/plans/:id/export_csv`

### Auth requirement

- Requires authentication via `Authorization: Bearer <token>`.

### Path parameter

| Name | Type    | Required | Notes                             |
| ---- | ------- | -------- | --------------------------------- |
| `id` | integer | yes      | Plan record ID from the database. |

### Query parameters

| Name     | Type   | Required | Default | Notes                                                |
| -------- | ------ | -------- | ------- | ---------------------------------------------------- |
| `format` | string | optional | `full`  | CSV format. Allowed values: `full`, `weeks`, `days`. |

### Behavior

- Returns the requested plan as a CSV file.
- The default format is `full` when the `format` query parameter is omitted.
- The response is sent as `text/csv` with a filename like `plan_<id>_<format>_<date>.csv`.

### Example request

```bash
curl -X GET "https://api.yourapp.com/api/v1/plans/42/export_csv" \
  -H "Authorization: Bearer <auth_token>"
```

### Example response

Status: `200 OK`

- Content-Type: `text/csv`
- Response body: CSV text

Example first CSV header row for the default `full` format:

```csv
Week,Dates,Type,Weekly Vert (ft),Time Cap,Mon,Tue,Wed,Thu,Fri,Sat,Sun
```

### Example query variations

- Full plan CSV:
  - `/api/v1/plans/42/export_csv`
- Week summary CSV:
  - `/api/v1/plans/42/export_csv?format=weeks`
- Day list CSV:
  - `/api/v1/plans/42/export_csv?format=days`

### Example error responses

- Invalid format:

Status: `400 Bad Request`

```json
{
  "error": {
    "status": 400,
    "message": "Bad request",
    "detail": "format must be one of: full, weeks, days"
  }
}
```

- Plan not found or not owned by user:

Status: `404 Not Found`

```json
{
  "error": {
    "status": 404,
    "message": "Resource not found",
    "detail": "Couldn't find Plan"
  }
}
```

- Unauthorized:

Status: `401 Unauthorized`

```json
{
  "error": "Unauthorized"
}
```

## 9. Error handling reference

| HTTP Status                 | Meaning                                                                       |
| --------------------------- | ----------------------------------------------------------------------------- |
| `200 OK`                    | Successful read or update action.                                             |
| `201 Created`               | Successful creation of a resource or session.                                 |
| `400 Bad Request`           | Required parameter missing or malformed request payload.                      |
| `401 Unauthorized`          | Missing or invalid authentication token, or invalid current password.         |
| `404 Not Found`             | Resource does not exist or is not accessible to the current user.             |
| `422 Unprocessable Entity`  | Validation failed for submitted data.                                         |
| `422 Unprocessable Content` | Duplicate user registration error path, or similar record constraint failure. |
