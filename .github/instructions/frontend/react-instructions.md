**name:** 'React Standards'
**description:** 'React coding conventions and guidelines'
**applyTo:** '**/*.jsx'

---

## React Specific Guidelines

## 1. General Guidelines & Logic Design
### Formatting and Naming 
- **Component Naming:** Use `PascalCase` for all component names (e.g., `MyButton`, `UserAvatar`).
- **Props:**
  - Use `camelCase` for prop names.
  - Destructure props in the component's function signature.
  - Provide clear `interface` or `type` definitions for props in TypeScript.

### Component Design
- **Functional Components & Hooks:** Prefer **functional components with React Hooks**. Avoid class components unless explicitly for error boundaries at the top of the component tree.
- **Immutability:** Never mutate props or state directly. Always create new objects or arrays for updates.
- **Fragments:** Use `<>...</>` or `React.Fragment` to avoid unnecessary DOM wrapper elements.
- **Keys:** 
  - Always provide a unique and stable `key` prop when mapping over lists. Do not use array `index` as a key if the list can change.
  - Use a key to reset state when conceptually unique components are renderd in the same position. (e.g a Profile component is unique for each user key)
- **State Management:**
    - Use proper state management techniques, avoid unnecessary use of state and Effects in React components.  
    - Do not use Effects to transform data for rendering. Transform all the data at the top level of components.
    - When something can be calculated from the existing props or state, don’t put it in state. Instead, calculate it during rendering.
    - Do not nest component function definitions.
  - **Local State:** Use `useState` for component-level state.
  - **Global State:** For global or shared state, prefer `useReducer` and or **React Context API**.  Avoid prop drilling.

### Single Responsibility
- Each component should ideally have one primary responsibility. **Components should be kept small and focused.**
- **Custom Hooks:** Extract reusable stateful logic into **custom hooks** (e.g., `useDebounce`, `useLocalStorage`).  Only extract when the logic has been used more than 2 times.
- **UI Components:** Use [shadcn/ui](https://ui.shadcn.com/) for building UI components to ensure consistency and accessibility.


### API Patterns
- Use React Query and **custom hooks** in React for API calls and data fetching.
- Handle loading and error states consistently in the UI when making API calls.

### Styling

- **Consistent Approach:** use Tailwind CSS v4 or later.
- **Scoped Styles:** Ensure styles are scoped to avoid global conflicts.

### Performance


- **Lazy Loading:** Suggest `React.lazy` and `Suspense` for code splitting large components or routes.
- Use [React Compiler](https://react.dev/learn/react-compiler/introduction) to optimize the React application at build time.


## 3. Project Structure
To keep the `src/` folder clean, categorize specialized logic here:
* **`src/components`:** component definitions
* **`src/hooks`:** custom hooks
* **`src/types`:** typescript interfaces
* **`src/services`:** logic shared across components
- **Colocation:** Colocate component files (JSX/TSX, CSS Modules, tests) within the appropriate directory. 
- **No Barrel Files:** Do not use barrel files (e.g., `index.ts` that re-exports from other files) for module exports. Always import directly from the specific file to improve traceability and avoid circular dependencies.

## 5. Testing & Debugging
### Testing
- Write unit tests for all components and functions using Jest, Enzyme, and React Testing Library.