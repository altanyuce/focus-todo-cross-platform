import { mergeHydrated } from '../state/todoReducer'
import {
  CURRENT_TASK_SCHEMA_VERSION,
  type Task,
  type TaskSyncMetadata,
} from '../types/task'
import type { CanonicalTask } from './canonicalTaskMapper'
import { toCanonicalTask } from './canonicalTaskMapper'
import { mergeTask } from './mergeEngine'
import {
  initializeMockSyncState,
  prepareMockOutboundPreview,
} from './mockSyncFlow'
import { markPendingDelete, markPendingUpsert } from './syncMetadata'

export interface SyncFoundationScenarioResult {
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

export function runSyncFoundationScenarios(): SyncFoundationScenarioResult[] {
  const results: SyncFoundationScenarioResult[] = []

  {
    const task = makeTask()
    const coordinatorState = initializeMockSyncState({
      tasks: [task],
      syncMetadata: markPendingUpsert([], task.id),
    })
    const outbound = prepareMockOutboundPreview(coordinatorState)
    assert(outbound.length === 1 && outbound[0].id === task.id, 'create task should appear in outbound candidates')
    results.push({ name: 'create task -> pending-upsert appears in outbound candidates', passed: true })
  }

  {
    const task = makeTask({ updatedAt: '2026-04-02T10:00:00.000Z' })
    const coordinatorState = initializeMockSyncState({
      tasks: [task],
      syncMetadata: markPendingUpsert(
        [makeMetadata(task.id, 'synced')],
        task.id,
      ),
    })
    const outbound = prepareMockOutboundPreview(coordinatorState)
    assert(outbound.length === 1 && outbound[0].id === task.id, 'updated task should remain outbound as pending-upsert')
    results.push({ name: 'update task -> pending-upsert remains outbound', passed: true })
  }

  {
    const task = makeTask({ deletedAt: '2026-04-02T11:00:00.000Z', updatedAt: '2026-04-02T11:00:00.000Z' })
    const coordinatorState = initializeMockSyncState({
      tasks: [task],
      syncMetadata: markPendingDelete([], task.id),
    })
    const outbound = prepareMockOutboundPreview(coordinatorState)
    assert(outbound.length === 1 && outbound[0].deleted_at !== null, 'deleted task should appear as pending-delete outbound')
    results.push({ name: 'delete task -> pending-delete appears in outbound candidates', passed: true })
  }

  {
    const localTask = makeTask({ updatedAt: '2026-04-02T09:00:00.000Z' })
    const remoteTask = makeTask({
      title: 'Remote newer',
      updatedAt: '2026-04-02T10:00:00.000Z',
      updatedByDeviceId: '22222222-2222-4222-8222-222222222222',
    })
    const merged = mergeTask(localTask, remoteTask)
    assert(merged.title === 'Remote newer', 'inbound newer record should beat older local record')
    results.push({ name: 'inbound newer record beats older local record', passed: true })
  }

  {
    const localTask = makeTask({ updatedAt: '2026-04-02T10:00:00.000Z' })
    const remoteTask = makeTask({
      updatedAt: '2026-04-02T10:00:00.000Z',
      deletedAt: '2026-04-02T10:00:00.000Z',
      updatedByDeviceId: '22222222-2222-4222-8222-222222222222',
    })
    const merged = mergeTask(localTask, remoteTask)
    assert(merged.deletedAt !== null, 'equal updatedAt with deleted remote should beat non-deleted local')
    results.push({ name: 'equal updatedAt + deleted remote beats non-deleted local', passed: true })
  }

  {
    const localTask = makeTask({
      updatedAt: '2026-04-02T10:00:00.000Z',
      updatedByDeviceId: '11111111-1111-4111-8111-111111111111',
    })
    const remoteTask = makeTask({
      updatedAt: '2026-04-02T10:00:00.000Z',
      updatedByDeviceId: '99999999-9999-4999-8999-999999999999',
    })
    const merged = mergeTask(localTask, remoteTask)
    assert(
      merged.updatedByDeviceId === remoteTask.updatedByDeviceId,
      'equal updatedAt and equal delete state should use device ID tie-break',
    )
    results.push({ name: 'equal updatedAt + equal delete state -> updatedByDeviceId tie-break works', passed: true })
  }

  {
    const localTask = makeTask()
    const remoteTask = makeTask()
    const merged = mergeTask(localTask, remoteTask)
    const remoteCanonical = toCanonicalTask(remoteTask)
    const mergedCanonical: CanonicalTask = toCanonicalTask(merged)
    assert(
      JSON.stringify(mergedCanonical) === JSON.stringify(remoteCanonical),
      'full equality should resolve to remote values',
    )
    results.push({ name: 'full equality -> remote wins', passed: true })
  }

  {
    const hydrated = mergeHydrated({
      deviceId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      taskData: {
        tasks: [
          {
            id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
            title: 'Legacy',
            note: '',
            dueDate: null,
            priority: 'medium',
            category: 'personal',
            completed: false,
            completedAt: null,
            createdAt: '2026-04-02T09:00:00.000Z',
            updatedAt: '2026-04-02T09:00:00.000Z',
            deletedAt: null,
            createdByDeviceId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
            updatedByDeviceId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          } as unknown as Task,
        ],
        syncMetadata: [],
      },
      ui: null,
    })
    assert(
      hydrated.tasks[0]?.schemaVersion === CURRENT_TASK_SCHEMA_VERSION,
      'missing schemaVersion in old local data should normalize to 1',
    )
    results.push({ name: 'schemaVersion missing in old local data normalizes to 1', passed: true })
  }

  return results
}
