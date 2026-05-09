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
5. Update the .devcontainer/compose.yaml file to explicitly map port 3000 from the container to your machine, and tell Puma to listen on all network interfaces instead of just localhost, so Docker's port mapping can reach it. Add the following lines to the `rails-app` service in the `compose.yaml` file:
    ```
    rails-app:
      build:
        context: ..
        dockerfile: .devcontainer/Dockerfile
      ports:
        - "3000:3000"  
      environment:
        - BINDING=0.0.0.0
    ```
6. Run `devcontainer up --workspace-folder .` to start the development container.
7. Once the container is up, run `devcontainer exec --workspace-folder . -- bin/dev` to start the Rails server.
8. You should now be able to access the Rails application by navigating to `http://localhost:3000` in your web browser. You should see the default Rails welcome page, confirming that the server is running correctly.
