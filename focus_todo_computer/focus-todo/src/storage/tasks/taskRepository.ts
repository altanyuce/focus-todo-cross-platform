import { loadLegacyState } from '../legacyState'
import type { TaskDataState } from '../../types/task'
import { LocalTaskDataSource } from './localTaskDataSource'

export interface TaskRepository {
  load(): TaskDataState | null
  save(data: TaskDataState): void
}

export class LocalTaskRepository implements TaskRepository {
  constructor(private readonly dataSource: LocalTaskDataSource) {}

  load(): TaskDataState | null {
    const persisted = this.dataSource.load()
    if (persisted?.data) {
      return persisted.data
    }

    const legacy = loadLegacyState()
    if (!legacy) return null

    return {
      tasks: legacy.tasks as TaskDataState['tasks'],
      syncMetadata: [],
    }
  }

  save(data: TaskDataState): void {
    this.dataSource.save(data)
  }
}

export const taskRepository = new LocalTaskRepository(new LocalTaskDataSource())
