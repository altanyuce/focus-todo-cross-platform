import {
  useEffect,
  useMemo,
  useReducer,
  useRef,
  type ReactNode,
} from 'react'
import { getOrCreateDeviceId } from '../storage/deviceIdentity'
import { taskRepository } from '../storage/tasks/taskRepository'
import { loadUiState, saveUiState } from '../storage/uiStateStorage'
import type { CanonicalTask } from '../sync/canonicalTaskMapper'
import {
  applyMockInboundTasks,
  initializeMockSyncState,
  prepareMockOutboundPreview,
  runMockSyncCycle,
} from '../sync/mockSyncFlow'
import { runRealSyncPipeline } from '../sync/realSyncPipeline'
import type { SyncCoordinatorState } from '../sync/syncCoordinator'
import {
  SyncTransportRegistry,
  type SyncTransportMode,
} from '../sync/syncTransportRegistry'
import { TodoContext } from './todoContext'
import { mergeHydrated, reducer } from './todoReducer'

export function TodoProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(reducer, undefined, () =>
    mergeHydrated({
      deviceId: getOrCreateDeviceId(),
      taskData: taskRepository.load(),
      ui: loadUiState(),
    }),
  )
  const saveTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const syncCoordinatorStateRef = useRef<SyncCoordinatorState | null>(null)
  const realSyncTransportRegistryRef = useRef<SyncTransportRegistry | null>(null)

  if (!realSyncTransportRegistryRef.current) {
    const registry = new SyncTransportRegistry()
    registry.setMode('supabase')
    realSyncTransportRegistryRef.current = registry
  }

  useEffect(() => {
    syncCoordinatorStateRef.current = initializeMockSyncState({
      tasks: state.tasks,
      syncMetadata: state.syncMetadata,
    })
  }, [state.tasks, state.syncMetadata])

  useEffect(() => {
    if (saveTimer.current) clearTimeout(saveTimer.current)
    saveTimer.current = setTimeout(() => {
      taskRepository.save({
        tasks: state.tasks,
        syncMetadata: state.syncMetadata,
      })
      saveUiState(state.ui)
    }, 400)
    return () => {
      if (saveTimer.current) clearTimeout(saveTimer.current)
    }
  }, [state.tasks, state.syncMetadata, state.ui])

  const realSyncTransportRegistry = realSyncTransportRegistryRef.current

  const value = useMemo(
    () => ({
      state,
      dispatch,
      mockSync: {
        getCoordinatorState() {
          return syncCoordinatorStateRef.current
        },
        prepareOutboundPreview() {
          const coordinatorState =
            syncCoordinatorStateRef.current ??
            initializeMockSyncState({
              tasks: state.tasks,
              syncMetadata: state.syncMetadata,
            })
          return prepareMockOutboundPreview(coordinatorState)
        },
        applyInboundTasks(mockData: CanonicalTask[]) {
          const coordinatorState =
            syncCoordinatorStateRef.current ??
            initializeMockSyncState({
              tasks: state.tasks,
              syncMetadata: state.syncMetadata,
            })
          const nextCoordinatorState = applyMockInboundTasks(
            coordinatorState,
            mockData,
          )
          syncCoordinatorStateRef.current = nextCoordinatorState
          dispatch({
            type: 'hydrate',
            state: {
              deviceId: state.deviceId,
              tasks: nextCoordinatorState.tasks,
              syncMetadata: nextCoordinatorState.syncMetadata,
              ui: state.ui,
            },
          })
        },
        runCycle(mockData: CanonicalTask[] = []) {
          const coordinatorState =
            syncCoordinatorStateRef.current ??
            initializeMockSyncState({
              tasks: state.tasks,
              syncMetadata: state.syncMetadata,
            })
          const result = runMockSyncCycle(coordinatorState, mockData)
          syncCoordinatorStateRef.current = result.coordinatorState
          if (mockData.length > 0) {
            dispatch({
              type: 'hydrate',
              state: {
                deviceId: state.deviceId,
                tasks: result.coordinatorState.tasks,
                syncMetadata: result.coordinatorState.syncMetadata,
                ui: state.ui,
              },
            })
          }
          return result.outboundBatch
        },
      },
      realSync: {
        async runOnce() {
          const transportMode = realSyncTransportRegistry.getMode()
          const result = await runRealSyncPipeline({
            currentTasks: state.tasks,
            currentSyncMetadata: state.syncMetadata,
            transport: realSyncTransportRegistry.getTransport(),
          })
          syncCoordinatorStateRef.current = result.coordinatorState
          dispatch({
            type: 'hydrate',
            state: {
              deviceId: state.deviceId,
              tasks: result.tasks,
              syncMetadata: result.syncMetadata,
              ui: state.ui,
            },
          })

          if (result.summary.success) {
            console.info('[focus-todo] sync completed', {
              transportMode,
              pushedCount: result.summary.pushedCount,
              pulledCount: result.summary.pulledCount,
              syncedCount: result.summary.syncedCount,
            })
          } else {
            console.error('[focus-todo] sync failed', {
              transportMode,
              errorMessage: result.summary.errorMessage,
              pushedCount: result.summary.pushedCount,
              errorCount: result.summary.errorCount,
            })
          }

          return result
        },
        getRemoteSnapshot() {
          return realSyncTransportRegistry.getRemoteSnapshot()
        },
        getTransportMode() {
          return realSyncTransportRegistry.getMode()
        },
        setTransportMode(mode: SyncTransportMode) {
          realSyncTransportRegistry.setMode(mode)
        },
      },
    }),
    [dispatch, realSyncTransportRegistry, state],
  )
  return <TodoContext.Provider value={value}>{children}</TodoContext.Provider>
}
