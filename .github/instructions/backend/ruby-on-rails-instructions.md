copilot rules for ruby files

---

description: 'Ruby on Rails coding conventions and guidelines'
applyTo: '\*_/_.rb'

---

# Ruby on Rails

## 1. General Guidelines & Logic Design

### **Formatting & Naming**

- **Standards:** Follow the RuboCop Style Guide; use `rubocop`, `standardrb`, or `rufo`.
- **Naming Conventions:** \* Use `snake_case` for variables/methods and `CamelCase` for classes/modules. Use UPPER_CASE for constants.
  - Favor meaningful names over comments; only comment when the "why" isn't obvious.
- **Self-Documentation:** Favor meaningful names over comments; only comment to explain the "why," not the "what."

### **Single Responsibility & Architecture**

- Controllers should parse params and return responses (JSON or error).
- Models should persist data and enforce constraints.
- When the same logic is used in at least 3 different places or the logic exceeds 15-20 lines, extract logic into service objects in app/services.

* **Service Objects:**
  - Each service should have a single exposed public method (i.e perform method).
  - Names should be verb-first and action-oriented. The name tells you exactly what the service does (e.g CreateUserAccount, CalculateTotal)
  - Errors should be caught inside the service and not be allowed to propagate up the call stack. Each service should catch its own domain errors and returns a Result
  - Write tests for the perform method. Mock external dependencies. Cover happy path, edge cases, and error conditions.

### **Method Patterns**

- **Method Design:** Keep methods short. Use early returns and guard clauses to reduce nesting. Use private methods to break the main operation down into readable tasks.
- **Conditionals:** Use `unless` for negative conditions, but never with an `else` block.
- **Safety:** Use safe navigation (`&.`) and prefer `.present?` / `.blank?` over manual nil checks.

---

## 2. Model & Database Layer

### **Data Integrity**

- **Constraints:** Define `null: false` and `unique: true` at the database level, not just in models.
- **Migrations:** Keep migrations database-agnostic; always add indexes for foreign keys and frequently queried columns.
- **Declarations:** Use enums and typed attributes for state management to provide clean helper methods.

### **Query Optimization**

- **Performance:** Use `find_each` when iterating over large datasets to preserve memory. Use `includes`, .`preload`, or `eager_load` to prevent N+1 queries.
- **Organization:** Keep complex queries inside the Model as scope declarations or dedicated Query Objects in app/queries.

---

## 3. App Directory Structure

To keep the `app/` folder clean, categorize specialized logic here:

- **`app/services`:** Business logic and external API interactions.
- **`app/queries`:** Complex ActiveRecord query encapsulation.
- **`app/serializers`:** Definitions for JSON responses (The Rails-to-React bridge).
- **`app/validators`:** Specialized custom validation classes.
- **`app/controllers/api/v1/`:** Versioned API endpoints.

---

## 4. API & Backend Best Practices

### **RESTful Design**

- **Routing:** Follow RESTful conventions and use namespaced routes (e.g., `/api/v1/`).
- **Responses:** Use proper HTTP status codes for each response (e.g., 200 OK, 201 Created, 422 Unprocessable Entity) and return errors in a structured JSON format.
  - Use `before_action` filters to load and authorize resources, not business logic.
  - Leverage pagination (e.g., `kaminari` or `pagy`) for endpoints returning large datasets.
  - Ensure sensitive data is never exposed in API responses or error messages.
- **Parameters:** Always sanitize and whitelist input via Strong Parameters.

### **Infrastructure**

- **Caching:** Use `Rails.cache` for expensive computations.
- **Security:** Keep secrets out of code; use .env for API keys and sensitive tokens..
- **CORS:** Use `rack-cors` to allow requests only from your React development server origin.
- **Pathing:** Construct file paths using `Rails.root.join(...)` rather than hardcoded strings.

---

## 5. Testing & Debugging

### **Test Strategy**

- Keep tests fast, reliable, and as DRY as production code.
- Avoid brittle tests — don’t rely on specific timestamps, randomized data, or order unless explicitly necessary.

* **Isolation:** Write unit tests for models/services and request/system tests for end-to-end flows.
* **Data Setup:** Use fixtures (Minitest) to create test data that mirrors realistic API payloads.

- Prefer `setup` in Minitest to initialize common test data.

* **Mocking:** Never hit external APIs; use `WebMock` or `VCR`.
* **Maintenance:** Use database cleaning tools (`rails test:prepare`, `DatabaseCleaner`, or `transactional_fixtures`) to ensure a fresh state between runs.

### **Debugging Tools**

- **Environment:** Avoid `puts`; use `byebug`, `pry`, or the Rails logger.
- **Documentation:** Use YARD or RDoc for complex paths.

---

## 6. Essential Commands

- **Scaffolding:** `rails generate` (use for consistent resource creation).
- **Database:** `rails db:migrate`, `db:rollback`, and `db:seed`.
- **Execution:** `rails console` (REPL), `rails server`, and `rails test`.
- **Audit:** `rails routes` to inspect the routing table.
