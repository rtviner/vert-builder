---
agent: agent
model: GPT-4.1
description: 'Create a Rails project, start it, and run it'
---

Your task is to create the Rails project in vert_builder directory using the ruby on rails framework.


To create the Rails project follow these steps.
1. Check if rails is installed by running `rails --version`. If it is not installed, install it with `gem install rails`.
2. Make sure you are in the root directory of the project.
3. Initialize a new Ruby on Rails project with the following command:
    ```
    rails new . --api -d postgresql --devcontainer
    --skip-js 
    --skip-action-mailer 
    --skip-action-mailbox 
    --skip-action-text 
    --skip-hotwire 
    --skip-action-cable 
    --skip-asset-pipeline
    ``` 
4. Confirm the docker container is running with the command `docker ps`. You should see a container for the Postgres database.
5. Run `devcontainer up --workspace-folder .` to start the development container.
6. run `bin/dev` to start the project. This will start the Rails server and the Postgres database in a Docker container.