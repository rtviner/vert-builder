#!/usr/bin/env -S just --justfile

up:
    devcontainer up --workspace-folder . && devcontainer exec --workspace-folder . bin/dev

console:
    devcontainer exec --workspace-folder . bin/rails console

migrate:
    devcontainer exec --workspace-folder . bin/rails db:migrate

down:
    docker compose -f .devcontainer/compose.yaml down

#bin/rails generate migration CreateProducts name:string part_number:string
# --> just generate_migration CreateProducts name:string part_number:string
#bin/rails generate migration AddPriceToProducts price:decimal
# --> just generate_migration AddPriceToProducts price:decimal
#bin/rails generate migration add_token_to_sessions token:uniq
# --> just generate_migration add_token_to_sessions token:uniq

generate_migration name *fields:
    devcontainer exec --workspace-folder . bin/rails generate migration {{name}} {{fields}}

generate_model name *fields:
    devcontainer exec --workspace-folder . bin/rails generate model {{name}} {{fields}}

run_test file:
    devcontainer exec --workspace-folder . bin/rails test {{file}}