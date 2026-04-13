# Focus — Tasks

A calm, desktop-first task list that runs in the browser. Data is stored locally with `localStorage` and persists between visits.

## Requirements

- [Node.js](https://nodejs.org/) 18+ (20.x recommended)

## Run locally

```bash
cd focus-todo
npm install
npm run dev
```

Open the URL shown in the terminal (usually `http://localhost:5173`).

## Scripts

| Command        | Description                    |
| -------------- | ------------------------------ |
| `npm run dev`  | Development server with HMR    |
| `npm run build`| Typecheck + production bundle  |
| `npm run preview` | Serve the `dist` folder     |
| `npm run lint` | ESLint                         |

## Stack

- **Vite 5** — fast dev and build
- **React 19** + **TypeScript**
- **Plain CSS** (modules + design tokens) — no UI framework, minimal surface area

## Project layout

- `src/types/` — shared types (`Task`, filters, UI state)
- `src/lib/` — date helpers and task query logic (sections, sorting)
- `src/storage/` — load/save JSON to `localStorage`
- `src/state/` — reducer, context provider, hooks (`useTodo`, `useTodoActions`)
- `src/components/` — layout, sidebar, task list, filters, quick add

## Behavior notes

- **Today**: incomplete tasks with no due date, or due on or before today.
- **Upcoming**: incomplete tasks with a due date after today.
- **Completed**: completed tasks (muted styling).
- **Lists**: Personal, Work, Study — each task has one list.
- **Theme**: Light, Dark, or Auto (follows the system). Choice is stored locally.

To package as a desktop app later, you can wrap the same UI with [Tauri](https://tauri.app/) or [Electron](https://www.electronjs.org/) without changing the core React code.
