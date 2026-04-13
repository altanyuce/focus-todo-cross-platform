import type { Task, TaskSyncMetadata } from '../types/task'
import { toCanonicalTask, fromCanonicalTask, type CanonicalTask } from './canonicalTaskMapper'
import { mergeTask } from './mergeEngine'
import { syncCoordinator } from './syncCoordinator'
import type { SyncTransport } from './syncTransport'

export class FakeSyncTransport implements SyncTransport {
  private readonly remoteTasks = new Map<string, CanonicalTask>()
  private nextPushError: string | null = null
  private nextPullError: string | null = null

  constructor(initialTasks: CanonicalTask[] = []) {
    for (const task of initialTasks) {
      this.remoteTasks.set(task.id, { ...task })
    }
  }

  failNextPush(message: string): void {
    this.nextPushError = message
  }

  failNextPull(message: string): void {
    this.nextPullError = message
  }

  snapshot(): CanonicalTask[] {
    return [...this.remoteTasks.values()]
      .map((task) => ({ ...task }))
      .sort((left, right) => left.id.localeCompare(right.id))
  }

  async pushTasks(outboundBatch: CanonicalTask[]): Promise<void> {
    if (this.nextPushError) {
      const message = this.nextPushError
      this.nextPushError = null
      throw new Error(message)
    }

    for (const outboundTask of outboundBatch) {
      const existing = this.remoteTasks.get(outboundTask.id)
      if (!existing) {
        this.remoteTasks.set(outboundTask.id, { ...outboundTask })
        continue
      }

      const merged = mergeTask(
        fromCanonicalTask(existing),
        fromCanonicalTask(outboundTask),
      )
      this.remoteTasks.set(outboundTask.id, toCanonicalTask(merged))
    }
  }

  async pullTasks(): Promise<CanonicalTask[]> {
    if (this.nextPullError) {
      const message = this.nextPullError
      this.nextPullError = null
      throw new Error(message)
    }

    return this.snapshot()
  }

  async syncOnce(
    currentTasks: Task[],
    currentSyncMetadata: TaskSyncMetadata[],
  ): Promise<CanonicalTask[]> {
    const outboundBatch = syncCoordinator.prepareOutboundBatch(
      syncCoordinator.initializeAfterHydration({
        tasks: currentTasks,
        syncMetadata: currentSyncMetadata,
      }),
    )

    await this.pushTasks(outboundBatch)
    return this.pullTasks()
  }
}
