import type { TaskSyncMetadata } from '../types/task'

interface MarkSyncedOptions {
  lastKnownServerUpdatedAt?: string | null
  lastSyncedAt?: string | null
}

function defaultSyncMetadata(taskId: string): TaskSyncMetadata {
  return {
    taskId,
    ownerUserId: null,
    syncStatus: 'pending-upsert',
    lastSyncedAt: null,
    lastKnownServerUpdatedAt: null,
    lastSyncError: null,
  }
}

function updateMetadata(
  syncMetadata: TaskSyncMetadata[],
  taskId: string,
  patch: Partial<TaskSyncMetadata>,
): TaskSyncMetadata[] {
  const existing = syncMetadata.find((item) => item.taskId === taskId)
  const next = {
    ...(existing ?? defaultSyncMetadata(taskId)),
    ...patch,
    taskId,
  }

  return [
    next,
    ...syncMetadata.filter((item) => item.taskId !== taskId),
  ]
}

export function markPendingUpsert(
  syncMetadata: TaskSyncMetadata[],
  taskId: string,
): TaskSyncMetadata[] {
  return updateMetadata(syncMetadata, taskId, {
    syncStatus: 'pending-upsert',
    lastSyncError: null,
  })
}

export function markPendingDelete(
  syncMetadata: TaskSyncMetadata[],
  taskId: string,
): TaskSyncMetadata[] {
  return updateMetadata(syncMetadata, taskId, {
    syncStatus: 'pending-delete',
    lastSyncError: null,
  })
}

export function markSynced(
  syncMetadata: TaskSyncMetadata[],
  taskId: string,
  options: MarkSyncedOptions = {},
): TaskSyncMetadata[] {
  return updateMetadata(syncMetadata, taskId, {
    syncStatus: 'synced',
    lastKnownServerUpdatedAt: options.lastKnownServerUpdatedAt ?? null,
    lastSyncedAt: options.lastSyncedAt ?? null,
    lastSyncError: null,
  })
}

export function markError(
  syncMetadata: TaskSyncMetadata[],
  taskId: string,
  error: string,
): TaskSyncMetadata[] {
  return updateMetadata(syncMetadata, taskId, {
    syncStatus: 'error',
    lastSyncError: error,
  })
}
