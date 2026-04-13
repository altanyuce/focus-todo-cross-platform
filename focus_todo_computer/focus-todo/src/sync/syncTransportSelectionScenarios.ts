import { runRealSyncPipeline } from './realSyncPipeline'
import { SyncTransportRegistry } from './syncTransportRegistry'
import { markPendingUpsert } from './syncMetadata'
import {
  CURRENT_TASK_SCHEMA_VERSION,
  type Task,
  type TaskSyncMetadata,
} from '../types/task'

export interface SyncTransportSelectionScenarioResult {
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

function findMetadata(
  syncMetadata: TaskSyncMetadata[],
  taskId: string,
): TaskSyncMetadata | undefined {
  return syncMetadata.find((item) => item.taskId === taskId)
}

export async function runSyncTransportSelectionScenarios(): Promise<
  SyncTransportSelectionScenarioResult[]
> {
  const results: SyncTransportSelectionScenarioResult[] = []

  {
    const registry = new SyncTransportRegistry()
    assert(registry.getMode() === 'fake', 'fake transport should remain the default')
    results.push({ name: 'fake transport remains the default', passed: true })
  }

  {
    const registry = new SyncTransportRegistry()
    registry.setMode('supabase')
    assert(
      registry.getMode() === 'supabase',
      'Supabase transport should be available only through explicit internal selection',
    )
    results.push({
      name: 'supabase transport is available only through explicit internal selection',
      passed: true,
    })
  }

  {
    const registry = new SyncTransportRegistry()
    const task = makeTask()
    const result = await runRealSyncPipeline({
      currentTasks: [task],
      currentSyncMetadata: markPendingUpsert([], task.id),
      transport: registry.getTransport(),
    })
    assert(
      result.summary.success && registry.getRemoteSnapshot().some((item) => item.id === task.id),
      'manual/internal sync should run with fake transport mode',
    )
    results.push({
      name: 'manual/internal sync can run with fake transport mode',
      passed: true,
    })
  }

  {
    const registry = new SyncTransportRegistry()
    registry.setMode('supabase')
    const task = makeTask()
    const result = await runRealSyncPipeline({
      currentTasks: [task],
      currentSyncMetadata: markPendingUpsert([], task.id),
      transport: registry.getTransport(),
    })
    const metadata = findMetadata(result.syncMetadata, task.id)
    assert(
      !result.summary.success &&
        metadata?.syncStatus === 'error' &&
        metadata.lastSyncError === 'Supabase sync is not configured',
      'missing Supabase config should stay safe and mark metadata as error',
    )
    results.push({
      name: 'missing Supabase config is safe under explicit Supabase selection',
      passed: true,
    })
  }

  return results
}
