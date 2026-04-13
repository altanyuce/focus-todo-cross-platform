import { loadLegacyState } from './legacyState'
import type { UiState } from '../types/task'

const UI_STATE_STORAGE_KEY = 'focus-todo-ui-state-v1'

interface PersistedUiStateSnapshot {
  version: number
  data: Partial<UiState>
}

export function loadUiState(): Partial<UiState> | null {
  try {
    const raw = localStorage.getItem(UI_STATE_STORAGE_KEY)
    if (raw) {
      const parsed = JSON.parse(raw) as PersistedUiStateSnapshot
      if (
        parsed?.data &&
        typeof parsed.data === 'object' &&
        !Array.isArray(parsed.data)
      ) {
        return parsed.data
      }
    }
  } catch {
    /* ignore */
  }

  return loadLegacyState()?.ui ?? null
}

export function saveUiState(ui: UiState): void {
  try {
    const snapshot: PersistedUiStateSnapshot = {
      version: 1,
      data: ui,
    }
    localStorage.setItem(UI_STATE_STORAGE_KEY, JSON.stringify(snapshot))
  } catch {
    /* ignore quota / private mode */
  }
}
