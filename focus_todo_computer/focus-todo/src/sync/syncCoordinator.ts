import type { Task, TaskSyncMetadata } from '../types/task'
import {
  fromCanonicalTask,
  toCanonicalTask,
  type CanonicalTask,
} from './canonicalTaskMapper'
import { mergeTask } from './mergeEngine'
import { getOutboundTasks } from './outboundSelector'
import {
  markError,
  markPendingDelete,
  markPendingUpsert,
  markSynced,
} from './syncMetadata'
import type { SyncWriteResult } from './syncTransport'

export interface SyncCoordinatorState {
  initializedAfterHydration: boolean
  tasks: Task[]
  syncMetadata: TaskSyncMetadata[]
}

export interface SyncCoordinator {
  initializeAfterHydration(input: {
    tasks: Task[]
    syncMetadata: TaskSyncMetadata[]
  }): SyncCoordinatorState
  prepareOutboundBatch(state: SyncCoordinatorState): CanonicalTask[]
  applyWriteResult(
    state: SyncCoordinatorState,
    taskId: string,
    result: SyncWriteResult,
  ): SyncCoordinatorState
  applyInboundBatch(
    state: SyncCoordinatorState,
    mockData: CanonicalTask[],
  ): SyncCoordinatorState
}

function sameWinner(left: Task, right: Task): boolean {
  return (
    left.schemaVersion === right.schemaVersion &&
    left.id === right.id &&
    left.title === right.title &&
    left.note === right.note &&
    left.dueDate === right.dueDate &&
    left.priority === right.priority &&
    left.category === right.category &&
    left.completed === right.completed &&
    left.completedAt === right.completedAt &&
    left.createdAt === right.createdAt &&
    left.updatedAt === right.updatedAt &&
    left.deletedAt === right.deletedAt &&
    left.createdByDeviceId === right.createdByDeviceId &&
    left.updatedByDeviceId === right.updatedByDeviceId
  )
}

export const syncCoordinator: SyncCoordinator = {
  initializeAfterHydration(input) {
    return {
      initializedAfterHydration: true,
      tasks: [...input.tasks],
      syncMetadata: [...input.syncMetadata],
    }
  },

  prepareOutboundBatch(state) {
    if (!state.initializedAfterHydration) return []
    return getOutboundTasks(state.tasks, state.syncMetadata).map(toCanonicalTask)
  },

  applyWriteResult(state, taskId, result) {
    if (!result.remoteTask) {
      return {
        initializedAfterHydration: state.initializedAfterHydration,
        tasks: [...state.tasks],
        syncMetadata: markError(
          state.syncMetadata,
          taskId,
          'Missing canonical row in sync write result',
        ),
      }
    }

    const remoteTask = fromCanonicalTask(result.remoteTask)
    const nextUpdatedAt = result.rowUpdatedAt ?? result.remoteTask.updated_at
    const existingLocalTask = state.tasks.find((task) => task.id === taskId)

    if (!existingLocalTask || result.applied) {
      return {
        initializedAfterHydration: state.initializedAfterHydration,
        tasks: [
          remoteTask,
          ...state.tasks.filter((task) => task.id !== remoteTask.id),
        ],
        syncMetadata: markSynced(state.syncMetadata, remoteTask.id, {
          lastKnownServerUpdatedAt: nextUpdatedAt,
        }),
      }
    }

    const mergedTask = mergeTask(existingLocalTask, remoteTask)

    return {
      initializedAfterHydration: state.initializedAfterHydration,
      tasks: state.tasks.map((task) =>
        task.id === mergedTask.id ? mergedTask : task,
      ),
      syncMetadata: sameWinner(mergedTask, remoteTask)
        ? markSynced(state.syncMetadata, remoteTask.id, {
            lastKnownServerUpdatedAt: nextUpdatedAt,
          })
        : mergedTask.deletedAt
          ? markPendingDelete(state.syncMetadata, mergedTask.id)
          : markPendingUpsert(state.syncMetadata, mergedTask.id),
    }
  },

  applyInboundBatch(state, mockData) {
    if (!state.initializedAfterHydration || mockData.length === 0) {
      return {
        initializedAfterHydration: state.initializedAfterHydration,
        tasks: [...state.tasks],
        syncMetadata: [...state.syncMetadata],
      }
    }

    let tasks = [...state.tasks]
    let syncMetadata = [...state.syncMetadata]

    for (const item of mockData) {
      const remoteTask = fromCanonicalTask(item)
      const localTask = tasks.find((task) => task.id === remoteTask.id)
      if (!localTask) {
        tasks = [...tasks, remoteTask]
        syncMetadata = markSynced(syncMetadata, remoteTask.id, {
          lastKnownServerUpdatedAt: item.updated_at,
        })
        continue
      }

      const mergedTask = mergeTask(localTask, remoteTask)
      tasks = tasks.map((task) => (task.id === mergedTask.id ? mergedTask : task))

      syncMetadata = sameWinner(mergedTask, remoteTask)
        ? markSynced(syncMetadata, remoteTask.id, {
            lastKnownServerUpdatedAt: item.updated_at,
          })
        : mergedTask.deletedAt
          ? markPendingDelete(syncMetadata, mergedTask.id)
          : markPendingUpsert(syncMetadata, mergedTask.id)
    }

    return {
      initializedAfterHydration: state.initializedAfterHydration,
      tasks,
      syncMetadata,
    }
  },
}
