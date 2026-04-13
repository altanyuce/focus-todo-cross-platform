import type { Task, TaskSyncMetadata } from '../types/task'
import type { CanonicalTask } from './canonicalTaskMapper'
import { syncCoordinator, type SyncCoordinatorState } from './syncCoordinator'
import { markError, markSynced } from './syncMetadata'
import type { SyncTransport } from './syncTransport'

export interface RealSyncPipelineResult {
  tasks: Task[]
  syncMetadata: TaskSyncMetadata[]
  coordinatorState: SyncCoordinatorState
  outboundBatch: CanonicalTask[]
  pulledRemoteTasks: CanonicalTask[]
  summary: {
    pushedCount: number
    pulledCount: number
    syncedCount: number
    errorCount: number
    success: boolean
    errorMessage: string | null
  }
}

function markRemoteTasksSynced(
  syncMetadata: TaskSyncMetadata[],
  remoteTasks: CanonicalTask[],
  lastSyncedAt: string,
): TaskSyncMetadata[] {
  return remoteTasks.reduce((current, remoteTask) => {
    const existing = current.find((item) => item.taskId === remoteTask.id)
    if (existing?.syncStatus !== 'synced') return current

    return markSynced(current, remoteTask.id, {
      lastKnownServerUpdatedAt: remoteTask.updated_at,
      lastSyncedAt,
    })
  }, syncMetadata)
}

function markOutboundTasksError(
  syncMetadata: TaskSyncMetadata[],
  outboundBatch: CanonicalTask[],
  errorMessage: string,
): TaskSyncMetadata[] {
  return outboundBatch.reduce(
    (current, task) => markError(current, task.id, errorMessage),
    syncMetadata,
  )
}

export async function runRealSyncPipeline(input: {
  currentTasks: Task[]
  currentSyncMetadata: TaskSyncMetadata[]
  transport: SyncTransport
}): Promise<RealSyncPipelineResult> {
  const coordinatorState = syncCoordinator.initializeAfterHydration({
    tasks: input.currentTasks,
    syncMetadata: input.currentSyncMetadata,
  })
  const outboundBatch = syncCoordinator.prepareOutboundBatch(coordinatorState)
  let nextCoordinatorState = coordinatorState
  let appliedCount = 0
  let errorCount = 0

  try {
    if (input.transport.writeTask) {
      for (const task of outboundBatch) {
        try {
          const expectedUpdatedAt =
            nextCoordinatorState.syncMetadata.find(
              (item) => item.taskId === task.id,
            )?.lastKnownServerUpdatedAt ?? null

          const result = await input.transport.writeTask(task, expectedUpdatedAt)
          nextCoordinatorState = syncCoordinator.applyWriteResult(
            nextCoordinatorState,
            task.id,
            result,
          )

          if (result.applied) {
            appliedCount += 1
          }
        } catch (error) {
          const errorMessage =
            error instanceof Error ? error.message : 'Sync transport failed'
          errorCount += 1
          nextCoordinatorState = {
            initializedAfterHydration:
              nextCoordinatorState.initializedAfterHydration,
            tasks: nextCoordinatorState.tasks,
            syncMetadata: markError(
              nextCoordinatorState.syncMetadata,
              task.id,
              errorMessage,
            ),
          }
        }
      }
    } else if (input.transport.syncOnce) {
      const pulledRemoteTasks = await input.transport.syncOnce(
        input.currentTasks,
        input.currentSyncMetadata,
      )
      const inboundAppliedState = syncCoordinator.applyInboundBatch(
        nextCoordinatorState,
        pulledRemoteTasks,
      )
      const lastSyncedAt = new Date().toISOString()
      const nextSyncMetadata = markRemoteTasksSynced(
        inboundAppliedState.syncMetadata,
        pulledRemoteTasks,
        lastSyncedAt,
      )

      return {
        tasks: inboundAppliedState.tasks,
        syncMetadata: nextSyncMetadata,
        coordinatorState: {
          initializedAfterHydration:
            inboundAppliedState.initializedAfterHydration,
          tasks: inboundAppliedState.tasks,
          syncMetadata: nextSyncMetadata,
        },
        outboundBatch,
        pulledRemoteTasks,
        summary: {
          pushedCount: outboundBatch.length,
          pulledCount: pulledRemoteTasks.length,
          syncedCount: pulledRemoteTasks.length,
          errorCount,
          success: errorCount === 0,
          errorMessage: null,
        },
      }
    } else {
      throw new Error('Sync transport does not support versioned writes')
    }

    const pulledRemoteTasks = await input.transport.pullTasks()
    const inboundAppliedState = syncCoordinator.applyInboundBatch(
      nextCoordinatorState,
      pulledRemoteTasks,
    )
    const lastSyncedAt = new Date().toISOString()
    const nextSyncMetadata = markRemoteTasksSynced(
      inboundAppliedState.syncMetadata,
      pulledRemoteTasks,
      lastSyncedAt,
    )

    return {
      tasks: inboundAppliedState.tasks,
      syncMetadata: nextSyncMetadata,
      coordinatorState: {
        initializedAfterHydration: inboundAppliedState.initializedAfterHydration,
        tasks: inboundAppliedState.tasks,
        syncMetadata: nextSyncMetadata,
      },
      outboundBatch,
      pulledRemoteTasks,
      summary: {
        pushedCount: appliedCount,
        pulledCount: pulledRemoteTasks.length,
        syncedCount: pulledRemoteTasks.length,
        errorCount,
        success: errorCount === 0,
        errorMessage: null,
      },
    }
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Sync transport failed'
    const nextSyncMetadata = markOutboundTasksError(
      nextCoordinatorState.syncMetadata,
      outboundBatch,
      errorMessage,
    )

    return {
      tasks: nextCoordinatorState.tasks,
      syncMetadata: nextSyncMetadata,
      coordinatorState: {
        initializedAfterHydration:
          nextCoordinatorState.initializedAfterHydration,
        tasks: nextCoordinatorState.tasks,
        syncMetadata: nextSyncMetadata,
      },
      outboundBatch,
      pulledRemoteTasks: [],
      summary: {
        pushedCount: appliedCount,
        pulledCount: 0,
        syncedCount: 0,
        errorCount: errorCount || outboundBatch.length,
        success: false,
        errorMessage,
      },
    }
  }
}
