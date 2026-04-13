import type { Task, TaskSyncMetadata } from '../types/task'
import {
  syncCoordinator,
  type SyncCoordinatorState,
} from './syncCoordinator'
import type { CanonicalTask } from './canonicalTaskMapper'

export interface MockSyncCycleResult {
  outboundBatch: CanonicalTask[]
  coordinatorState: SyncCoordinatorState
}

export function initializeMockSyncState(input: {
  tasks: Task[]
  syncMetadata: TaskSyncMetadata[]
}): SyncCoordinatorState {
  return syncCoordinator.initializeAfterHydration(input)
}

export function prepareMockOutboundPreview(
  coordinatorState: SyncCoordinatorState,
): CanonicalTask[] {
  return syncCoordinator.prepareOutboundBatch(coordinatorState)
}

export function applyMockInboundTasks(
  coordinatorState: SyncCoordinatorState,
  mockData: CanonicalTask[],
): SyncCoordinatorState {
  return syncCoordinator.applyInboundBatch(coordinatorState, mockData)
}

export function runMockSyncCycle(
  coordinatorState: SyncCoordinatorState,
  mockData: CanonicalTask[] = [],
): MockSyncCycleResult {
  const outboundBatch = prepareMockOutboundPreview(coordinatorState)
  const nextCoordinatorState = applyMockInboundTasks(coordinatorState, mockData)

  return {
    outboundBatch,
    coordinatorState: nextCoordinatorState,
  }
}
