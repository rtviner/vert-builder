---
applyTo: "**"
---

# VertBuilder Fitness App Setup and Structure Guidelines

## Explain the VertBuilder Planner and Tracker App goals and steps

I want to build a VertBuilder Planner and Tracker app that will include the following:

* User authentication and profiles
* Fitness plan creation and customization
* Activity logging and tracking
* Strava API integration for automatic activity tracking
* Progress dashboard with visualizations

## Never change directories when agent mode is running commands

- Never change directories
- Instead point to the directory when issuing commands

## Forwarded ports

- 8000: public
- 3000: public
- 27017: private

Do not propose any other ports to forward or to make public 

## VertBuilder App structure

The section defines the VertBuilder App's structure

```text
vert_builder/
├── app/
│   ├── services/
|   ├── queries/
|   ├── models/
│   ├── serializers/
│   ├── validators/
│   ├──  controllers/api/v1/
│   ├── tests/
└── └─  frontend/
      ├── entrypoints/
      ├── components/
      ├── hooks/
      └── types/  
```

## Tech stack in use

### Backend
- Ruby on Rails and Postgres in a Docker container for the API and database.

### Frontend
- React with TypeScript for the frontend.  
- The React app is built using Vite and uses Tailwind CSS for styling.  
- React Query is used for data fetching and state management, and shadcn/ui is used for UI components.


## General Principles

- **Clean Code:** Prioritize **readability, maintainability, and reusability**.
- **Conciseness:** Aim for concise and expressive code.
- **Descriptive Naming:** Use clear and descriptive names for variables, functions, components, and files (e.g., `getUserProfile`, `ProductCard`, `useAuth`).
- **Modularization:** Break down complex problems and features into smaller, manageable units (components, functions, utilities).  Features and problems are too complex if the logic exceeds 15-20 lines.
- **TypeScript First:** All new code should be written in **TypeScript**, leveraging its type safety features.
- **Testable Code:** Design code to be easily testable.
- **Package Management:** This project uses **pnpm** for managing dependencies. All package installations and scripts should use `pnpm` instead of `npm` or `yarn`.
- **Documentation:** All principal documentation should be created in the `docs` folder.

### General Guidelines

- **Co-locate logic that change together**
- **Separate UI, logic, and data fetching**
- **Typesafety across the whole stack – db-server-client. If a type changes, everywhere using it should be aware.**
- **Clear product logic vs product infrastructure separation**
- **Design code such that it is easy to replace and delete**
- **Minimize places/number of changes to extend features**
- **Functions / APIs should do one thing well. One level of abstraction per function**
- **Minimize API interface and expose only what's necessary**
- **Favor pure functions, it makes logic easy to test**
- **Long, clear names over short, vague names, even at the cost of verbosity**

---



