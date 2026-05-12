#!/usr/bin/env -S just --justfile

up:
    devcontainer up --workspace-folder . && devcontainer exec --workspace-folder . bin/dev

console:
    devcontainer exec --workspace-folder . bin/rails console

migrate:
    devcontainer exec --workspace-folder . bin/rails db:migrate

down:
    docker compose down