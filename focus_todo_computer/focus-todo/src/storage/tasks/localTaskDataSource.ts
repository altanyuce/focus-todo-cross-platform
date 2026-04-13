import type { TaskDataState } from '../../types/task'

const TASK_DATA_STORAGE_KEY = 'focus-todo-task-data-v2'

interface PersistedTaskDataSnapshot {
  version: number
  data: TaskDataState
}

export class LocalTaskDataSource {
  load(): PersistedTaskDataSnapshot | null {
    try {
      const raw = localStorage.getItem(TASK_DATA_STORAGE_KEY)
      if (!raw) return null

      const parsed = JSON.parse(raw) as PersistedTaskDataSnapshot
      if (!parsed || typeof parsed !== 'object') return null

      return parsed
    } catch {
      return null
    }
  }

  save(data: TaskDataState): void {
    try {
      const snapshot: PersistedTaskDataSnapshot = {
        version: 2,
        data,
      }
      localStorage.setItem(TASK_DATA_STORAGE_KEY, JSON.stringify(snapshot))
    } catch {
      /* ignore quota / private mode */
    }
  }
}
