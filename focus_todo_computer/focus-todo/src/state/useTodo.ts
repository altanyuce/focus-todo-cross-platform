import { useCallback, useContext } from 'react'
import type {
  Category,
  Priority,
  TaskUpdatePatch,
  UiState,
} from '../types/task'
import type { CanonicalTask } from '../sync/canonicalTaskMapper'
import type { SyncTransportMode } from '../sync/syncTransportRegistry'
import { TodoContext } from './todoContext'

export function useTodo() {
  const ctx = useContext(TodoContext)
  if (!ctx) throw new Error('useTodo must be used within TodoProvider')
  return ctx
}

export function useTodoActions() {
  const { dispatch } = useTodo()

  const addTask = useCallback(
    (payload: {
      title: string
      note: string
      dueDate: string | null
      priority: Priority
      category: Category
    }) => dispatch({ type: 'add', ...payload }),
    [dispatch],
  )

  const updateTask = useCallback(
    (id: string, patch: TaskUpdatePatch) =>
      dispatch({ type: 'update', id, patch }),
    [dispatch],
  )

  const deleteTask = useCallback(
    (id: string) => dispatch({ type: 'delete', id }),
    [dispatch],
  )

  const toggleComplete = useCallback(
    (id: string) => dispatch({ type: 'toggleComplete', id }),
    [dispatch],
  )

  const setUi = useCallback(
    (patch: Partial<UiState>) => dispatch({ type: 'setUi', patch }),
    [dispatch],
  )

  return {
    addTask,
    updateTask,
    deleteTask,
    toggleComplete,
    setUi,
  }
}

export function useTodoMockSync() {
  const { mockSync } = useTodo()

  const getCoordinatorState = useCallback(
    () => mockSync.getCoordinatorState(),
    [mockSync],
  )

  const prepareOutboundPreview = useCallback(
    () => mockSync.prepareOutboundPreview(),
    [mockSync],
  )

  const applyInboundTasks = useCallback(
    (mockData: CanonicalTask[]) => mockSync.applyInboundTasks(mockData),
    [mockSync],
  )

  const runCycle = useCallback(
    (mockData?: CanonicalTask[]) => mockSync.runCycle(mockData),
    [mockSync],
  )

  return {
    getCoordinatorState,
    prepareOutboundPreview,
    applyInboundTasks,
    runCycle,
  }
}

export function useTodoRealSync() {
  const { realSync } = useTodo()

  const runOnce = useCallback(() => realSync.runOnce(), [realSync])
  const getRemoteSnapshot = useCallback(
    () => realSync.getRemoteSnapshot(),
    [realSync],
  )
  const getTransportMode = useCallback(
    () => realSync.getTransportMode(),
    [realSync],
  )
  const setTransportMode = useCallback(
    (mode: SyncTransportMode) => realSync.setTransportMode(mode),
    [realSync],
  )

  return {
    runOnce,
    getRemoteSnapshot,
    getTransportMode,
    setTransportMode,
  }
}
