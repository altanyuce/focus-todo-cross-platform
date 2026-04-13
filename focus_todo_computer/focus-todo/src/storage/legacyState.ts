import type { Task, UiState } from '../types/task'

const LEGACY_STORAGE_KEY = 'focus-todo-state-v1'

export interface LegacyPersistedState {
  tasks: Partial<Task>[]
  ui: Partial<UiState> | null
}

export function loadLegacyState(): LegacyPersistedState | null {
  try {
    const raw = localStorage.getItem(LEGACY_STORAGE_KEY)
    if (!raw) return null

    const parsed = JSON.parse(raw) as {
      tasks?: unknown
      ui?: unknown
    }

    return {
      tasks: Array.isArray(parsed?.tasks)
        ? (parsed.tasks as Partial<Task>[])
        : [],
      ui:
        parsed?.ui &&
        typeof parsed.ui === 'object' &&
        !Array.isArray(parsed.ui)
          ? (parsed.ui as Partial<UiState>)
          : null,
    }
  } catch {
    return null
  }
}
