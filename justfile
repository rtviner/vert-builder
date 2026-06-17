#!/usr/bin/env -S just --justfile

up:
    devcontainer up --workspace-folder . && devcontainer exec --workspace-folder . bin/dev

console:
    devcontainer exec --workspace-folder . bin/rails console

migrate:
    devcontainer exec --workspace-folder . bin/rails db:migrate

load_fixtures:
    devcontainer exec --workspace-folder . bin/rails db:fixtures:load

down *flags:
    docker compose -f .devcontainer/compose.yaml down {{flags}}

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

generate_controller name *actions:
    devcontainer exec --workspace-folder . bin/rails generate controller {{name}} {{actions}}

destroy_generate type name:
    devcontainer exec --workspace-folder . bin/rails destroy {{type}} {{name}}
run_test file:
    devcontainer exec --workspace-folder . bin/rails test {{file}}