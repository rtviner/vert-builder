# Copilot Instructions

## Vert Builder Project Overview

- **Overview:** This is a web app to build and track fitness plans for maintaining and increasing vertical feet of elevation achieved during walk, hike, trailrun, or backcountry ski activity. 
  -  Users can create fitness plans by inputting a specific goal "event" elevation gain (e.g 4000 ft) and plan duration (e.g 16 weeks) along with current fitness parameters (i.e average vertical gain per week, average hours of activities per week) and desired aggresiveness of plan (i.e conservative, moderate, aggressive). 
    - The aggresiveness of the plan is determined by the weekly increase in elevation gain and hours of activity. 
  - Recovery weeks are also included in the plan and the pattern of build and recovery weeks can be customized (e.g recovery every other week, every fourth week) by the user. 
    - Recovery weeks are defined as a week with a 40-60% decrease in elevation gain and can be adjusted as needed
  - The app also provides a dashboard to view the planned elevation gain and hours of activity for each week of the plan and track progress towards the goal.
  - Plan completion progress can be tracked over time manually and via integration with the Strava API.
  

## Tech stack in use

### Backend
- Ruby on Rails and Postgres in a Docker container for the API and database.


### Frontend
- React with TypeScript for the frontend.  The React app is built using Vite and uses Tailwind CSS for styling.  React Query is used for data fetching and state management, and shadcn/ui is used for UI components.



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



