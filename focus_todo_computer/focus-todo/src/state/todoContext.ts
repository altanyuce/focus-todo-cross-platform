import { createContext, type Dispatch } from 'react'
import type { Action, State } from './todoReducer'
import type { CanonicalTask } from '../sync/canonicalTaskMapper'
import type { RealSyncPipelineResult } from '../sync/realSyncPipeline'
import type { SyncCoordinatorState } from '../sync/syncCoordinator'
import type { SyncTransportMode } from '../sync/syncTransportRegistry'

export const TodoContext = createContext<{
  state: State
  dispatch: Dispatch<Action>
  mockSync: {
    getCoordinatorState(): SyncCoordinatorState | null
    prepareOutboundPreview(): CanonicalTask[]
    applyInboundTasks(mockData: CanonicalTask[]): void
    runCycle(mockData?: CanonicalTask[]): CanonicalTask[]
  }
  realSync: {
    runOnce(): Promise<RealSyncPipelineResult>
    getRemoteSnapshot(): CanonicalTask[]
    getTransportMode(): SyncTransportMode
    setTransportMode(mode: SyncTransportMode): void
  }
} | null>(null)
