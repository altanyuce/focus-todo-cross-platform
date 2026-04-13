import type { Task, TaskSyncMetadata } from '../types/task'
import type { CanonicalTask } from './canonicalTaskMapper'

export interface SyncWriteResult {
  applied: boolean
  conflict: boolean
  remoteTask: CanonicalTask | null
  rowUpdatedAt: string | null
}

export interface SyncTransport {
  pushTasks?(outboundBatch: CanonicalTask[]): Promise<void>
  pullTasks(): Promise<CanonicalTask[]>
  syncOnce?(
    currentTasks: Task[],
    currentSyncMetadata: TaskSyncMetadata[],
  ): Promise<CanonicalTask[]>
  writeTask?(
    task: CanonicalTask,
    expectedUpdatedAt: string | null,
  ): Promise<SyncWriteResult>
}
