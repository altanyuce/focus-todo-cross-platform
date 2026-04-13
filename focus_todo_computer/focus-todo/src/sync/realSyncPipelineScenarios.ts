import {
  CURRENT_TASK_SCHEMA_VERSION,
  type Task,
  type TaskSyncMetadata,
} from '../types/task'
import { toCanonicalTask } from './canonicalTaskMapper'
import { FakeSyncTransport } from './fakeSyncTransport'
import { runRealSyncPipeline } from './realSyncPipeline'
import { markPendingDelete, markPendingUpsert } from './syncMetadata'

export interface RealSyncPipelineScenarioResult {
  name: string
  passed: boolean
}

function assert(condition: boolean, message: string): void {
  if (!condition) {
    throw new Error(message)
  }
}

function makeTask(overrides: Partial<Task> = {}): Task {
  return {
    schemaVersion: CURRENT_TASK_SCHEMA_VERSION,
    id: '11111111-1111-4111-8111-111111111111',
    title: 'Task',
    note: '',
    dueDate: null,
    priority: 'medium',
    category: 'personal',
    completed: false,
    completedAt: null,
    createdAt: '2026-04-02T09:00:00.000Z',
    updatedAt: '2026-04-02T09:00:00.000Z',
    deletedAt: null,
    createdByDeviceId: '11111111-1111-4111-8111-111111111111',
    updatedByDeviceId: '11111111-1111-4111-8111-111111111111',
    ...overrides,
  }
}

function makeMetadata(
  taskId: string,
  syncStatus: TaskSyncMetadata['syncStatus'],
): TaskSyncMetadata {
  return {
    taskId,
    ownerUserId: null,
    syncStatus,
    lastSyncedAt: null,
    lastKnownServerUpdatedAt: null,
    lastSyncError: null,
  }
}

function findMetadata(
  syncMetadata: TaskSyncMetadata[],
  taskId: string,
): TaskSyncMetadata | undefined {
  return syncMetadata.find((item) => item.taskId === taskId)
}

export async function runRealSyncPipelineScenarios(): Promise<
  RealSyncPipelineScenarioResult[]
> {
  const results: RealSyncPipelineScenarioResult[] = []

  {
    const task = makeTask()
    const transport = new FakeSyncTransport()
    await runRealSyncPipeline({
      currentTasks: [task],
      currentSyncMetadata: markPendingUpsert([], task.id),
      transport,
    })
    assert(transport.snapshot().some((remote) => remote.id === task.id), 'pending-upsert task should be pushed to remote')
    results.push({ name: 'pending-upsert task is pushed to remote', passed: true })
  }

  {
    const task = makeTask({
      deletedAt: '2026-04-02T10:00:00.000Z',
      updatedAt: '2026-04-02T10:00:00.000Z',
    })
    const transport = new FakeSyncTransport()
    await runRealSyncPipeline({
      currentTasks: [task],
      currentSyncMetadata: markPendingDelete([], task.id),
      transport,
    })
    const remote = transport.snapshot().find((item) => item.id === task.id)
    assert(remote?.deleted_at !== null, 'pending-delete tombstone should be pushed to remote')
    results.push({ name: 'pending-delete tombstone is pushed to remote', passed: true })
  }

  {
    const remoteTask = toCanonicalTask(
      makeTask({
        id: '22222222-2222-4222-8222-222222222222',
        title: 'Remote only',
        updatedByDeviceId: '22222222-2222-4222-8222-222222222222',
        createdByDeviceId: '22222222-2222-4222-8222-222222222222',
      }),
    )
    const transport = new FakeSyncTransport([remoteTask])
    const result = await runRealSyncPipeline({
      currentTasks: [],
      currentSyncMetadata: [],
      transport,
    })
    assert(
      result.tasks.some((task) => task.id === remoteTask.id),
      'pulled remote tasks should be merged back locally',
    )
    results.push({ name: 'pulled remote tasks are merged back locally', passed: true })
  }

  {
    const localTask = makeTask({ title: 'Local', updatedAt: '2026-04-02T09:00:00.000Z' })
    const remoteTask = toCanonicalTask(
      makeTask({
        title: 'Remote newer',
        updatedAt: '2026-04-02T10:00:00.000Z',
        updatedByDeviceId: '22222222-2222-4222-8222-222222222222',
      }),
    )
    const transport = new FakeSyncTransport([remoteTask])
    const result = await runRealSyncPipeline({
      currentTasks: [localTask],
      currentSyncMetadata: [makeMetadata(localTask.id, 'synced')],
      transport,
    })
    assert(
      result.tasks.find((task) => task.id === localTask.id)?.title === 'Remote newer',
      'remote newer task should update local task',
    )
    results.push({ name: 'remote newer task updates local task', passed: true })
  }

  {
    const localTask = makeTask({ updatedAt: '2026-04-02T10:00:00.000Z' })
    const remoteTask = toCanonicalTask(
      makeTask({
        updatedAt: '2026-04-02T10:00:00.000Z',
        deletedAt: '2026-04-02T10:00:00.000Z',
        updatedByDeviceId: '22222222-2222-4222-8222-222222222222',
      }),
    )
    const transport = new FakeSyncTransport([remoteTask])
    const result = await runRealSyncPipeline({
      currentTasks: [localTask],
      currentSyncMetadata: [makeMetadata(localTask.id, 'synced')],
      transport,
    })
    assert(
      result.tasks.find((task) => task.id === localTask.id)?.deletedAt !== null,
      'remote tombstone should beat equal-timestamp local active task',
    )
    results.push({ name: 'remote tombstone beats equal-timestamp local active task', passed: true })
  }

  {
    const task = makeTask()
    const transport = new FakeSyncTransport()
    const result = await runRealSyncPipeline({
      currentTasks: [task],
      currentSyncMetadata: markPendingUpsert([], task.id),
      transport,
    })
    const metadata = findMetadata(result.syncMetadata, task.id)
    assert(
      metadata?.syncStatus === 'synced' && metadata.lastSyncedAt !== null,
      'successful sync should mark relevant metadata as synced',
    )
    results.push({ name: 'successful sync marks relevant metadata as synced', passed: true })
  }

  {
    const task = makeTask()
    const transport = new FakeSyncTransport()
    transport.failNextPush('push failed')
    const result = await runRealSyncPipeline({
      currentTasks: [task],
      currentSyncMetadata: markPendingUpsert([], task.id),
      transport,
    })
    const metadata = findMetadata(result.syncMetadata, task.id)
    assert(
      metadata?.syncStatus === 'error' &&
        metadata.lastSyncError === 'push failed',
      'failed transport should mark metadata as error',
    )
    results.push({ name: 'failed transport marks metadata as error', passed: true })
  }

  {
    const task = makeTask()
    const transport = new FakeSyncTransport()
    const first = await runRealSyncPipeline({
      currentTasks: [task],
      currentSyncMetadata: markPendingUpsert([], task.id),
      transport,
    })
    const second = await runRealSyncPipeline({
      currentTasks: first.tasks,
      currentSyncMetadata: first.syncMetadata,
      transport,
    })
    assert(
      first.summary.success &&
        second.summary.success &&
        second.outboundBatch.length === 0,
      'running sync twice should be stable and leave no new outbound work',
    )
    results.push({ name: 'running sync twice is stable/idempotent enough for v1 prototype expectations', passed: true })
  }

  return results
}
