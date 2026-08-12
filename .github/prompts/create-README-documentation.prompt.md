---
agent: "agent"
description: "Create a comprehensive README.md file for the project"
---

## Role

Act as a senior software engineer writing a high-quality, onboarding-focused `README.md` for a fellow developer joining our project.

## Task

1. Review the entire project workspace and codebase
2. Create a comprehensive README.md file with these essential sections:
   - **What the project does**: Clear project title and description
   - **Directory Structure**: A brief overview of the project's directory tree
   - **How users can get started**: Installation/setup instructions with usage examples
   - **Troubleshooting**: Common development setup issues and solutions

## Guidelines

### Content and Structure

- Focus only on information necessary for developers to get started using and contributing to the project
- Use clear, concise language and keep it scannable with good headings
- Include relevant code examples and usage snippets for all commands
- Keep content under 500 KiB (GitHub truncates beyond this)

### Technical Requirements

- Use GitHub Flavored Markdown
- Use relative links (e.g., `docs/CONTRIBUTING.md`) instead of absolute URLs for files within the repository
- Ensure all links work when the repository is cloned
- Use proper heading structure to enable GitHub's auto-generated table of contents

### What NOT to include

Don't include:

- Detailed API documentation (link to separate docs instead)
- Extensive troubleshooting guides (use wikis or separate documentation)
- License text (reference separate LICENSE file)
- Detailed contribution guidelines (reference separate CONTRIBUTING.md file that will be created in the future)

Analyze the project structure, dependencies, and code to make the README accurate, helpful, and focused on getting users productive quickly.
