# VertBuilder Planner & Tracker

## What is VertBuilder?

VertBuilder is a Rails API backend for building fitness plans. It provides:

- User authentication and profiles
- Fitness plan creation and customization
- Weekly and daily targets to reach plan goal
- CSV export for full plans, weeks of plan, and days of plan
- Token-based API access for clients

## Technology stack

- Ruby on Rails 8.1 (API mode)
- PostgreSQL
- Puma web server
- Minitest for automated tests
- Docker Dev Container for local development

## Setup & Quick Start

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) or [OrbStack](https://orbstack.dev/) (provides both the Docker Engine and `docker compose` CLI)
- [Visual Studio Code](https://code.visualstudio.com/) + [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- _Optional (if developing without the vs code extension):_ `devcontainer` CLI and `just` task runner installed on your host machine.

### Option A: VS Code Setup

1. **Clone and open the repository:**
   ```bash
   git clone [https://github.com/rtviner/vert-builder.git](https://github.com/rtviner/vert-builder.git)
   cd vert-builder
   code .
   ```
2. Reopen in container: Press F1 and select Dev Containers: Reopen in Container.
   VS Code will build the container, run initial setup scripts, and start the server automatically.

### Option B: Terminal Setup (Using just)

If you are not using VS Code, use the provided justfile wrappers:

1. **Clone and open the repository:**
   ```bash
   git clone [https://github.com/rtviner/vert-builder.git](https://github.com/rtviner/vert-builder.git)
   cd vert-builder
   just up
   ```
   Note: just up (or bin/start on host) builds the devcontainer, installs Ruby gems, prepares the database, clears temporary files, and boots the Rails API server.

### Verify setup:

Access the server at http://localhost:3000 (should see the rails logo).

### Troubleshooting & Manual Updates

If you pull new changes from git, or if the container startup script fails midway, you can manually sync gems and the database inside the container without booting the web server:

```bash
bin/setup --skip-server
```

This re-syncs gems and database migrations without starting a duplicate Rails server process.

### Stop the development environment

from your host shell:

```bash
just down
```

To stop containers and also remove database volumes:

```bash
just down -v
```

## Database

The project uses PostgreSQL. The devcontainer compose file is at `.devcontainer/compose.yaml`.
The database service is exposed locally on port `5432` inside the container.

### Common database commands

from inside the container shell:

```bash
bin/rails db:prepare
bin/rails db:migrate
bin/rails db:reset
bin/rails db:fixtures:load
```

from the host machine:

```bash
devcontainer exec --workspace-folder . bin/rails db:prepare
just migrate
devcontainer exec --workspace-folder . bin/rails db:reset
just load_fixtures
```

## Run the test suite

Run tests inside the container or via just wrappers on your host:

Run a specific test file:

```bash
just run_test test/models/plan_test.rb
```

Or run the full suite with:

```bash
just run_test test
```

## Project structure

Key folders and responsibilities:

- `app/controllers/` - API controllers and request handling
- `app/models/` - Active Record models and domain data
- `app/services/` - business logic and plan/day generation
- `app/jobs/` - background job classes
- `config/` - Rails configuration and routes
- `db/` - migrations, schema, and seed data
- `test/` - unit and integration tests
- `docs/` - project documentation and API reference

## API documentation

Primary API documentation is maintained in `docs/api-documentation.md`.
Refer to that file for available endpoints, request examples, and authentication details.

## Authentication

API access is protected by bearer token authentication.
Send requests with:

```http
Authorization: Bearer <token>
```

Session tokens are managed through the app's session model and issued when users authenticate.

## Useful Host commands (justfile)

- `just up` - start the development container and server
- `just down` - stop the containerized environment
- `just run_test <file>` - run a specific Rails test file
- `just migrate` - run Rails database migrations

## Contributing

- Keep controller actions focused on request/response handling.
- Put reusable business logic in `app/services/`.
- Add tests for any new plan generation or export behavior.
- Update `docs/api-documentation.md` when adding or changing API routes.

## Notes

This repository is structured for a Rails-first backend API. If you add frontend components or client apps, keep API contract changes aligned with the documentation in `docs/api-documentation.md`.
