import { SORT_ORDERS } from '../types/task'
import type {
  CategoryFilter,
  Category,
  PriorityFilter,
  Priority,
  Section,
  StatusFilter,
  Task,
  TaskDataState,
  TaskSyncMetadata,
  TaskSyncStatus,
  TaskUpdatePatch,
  UiState,
} from '../types/task'
import { CURRENT_TASK_SCHEMA_VERSION as TASK_SCHEMA_VERSION } from '../types/task'

export const defaultUi: UiState = {
  section: 'today',
  search: '',
  statusFilter: 'all',
  priorityFilter: 'all',
  categoryFilter: 'all',
  sortOrder: 'default',
}

export interface State {
  deviceId: string
  tasks: Task[]
  syncMetadata: TaskSyncMetadata[]
  ui: UiState
}

export type Action =
  | { type: 'hydrate'; state: State }
  | {
      type: 'add'
      title: string
      note: string
      dueDate: string | null
      priority: Priority
      category: Category
    }
  | { type: 'update'; id: string; patch: TaskUpdatePatch }
  | { type: 'delete'; id: string }
  | { type: 'toggleComplete'; id: string }
  | { type: 'setUi'; patch: Partial<UiState> }

function nowIso(): string {
  return new Date().toISOString()
}

function isUuid(value: unknown): value is string {
  return (
    typeof value === 'string' &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
      value,
    )
  )
}

function isIsoTimestamp(value: unknown): value is string {
  return typeof value === 'string' && !Number.isNaN(Date.parse(value))
}

function normalizeOptionalTimestamp(value: unknown): string | null {
  return isIsoTimestamp(value) ? value : null
}

function normalizeLocalDate(value: unknown): string | null {
  return typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value)
    ? value
    : null
}

function normalizeSchemaVersion(value: unknown): number {
  return Number.isInteger(value) && Number(value) > 0
    ? Number(value)
    : TASK_SCHEMA_VERSION
}

function isStatusFilter(value: unknown): value is StatusFilter {
  return value === 'all' || value === 'active' || value === 'done'
}

function isPriorityFilter(value: unknown): value is PriorityFilter {
  return value === 'all' || value === 'low' || value === 'medium' || value === 'high'
}

function isCategoryFilter(value: unknown): value is CategoryFilter {
  return value === 'all' || value === 'personal' || value === 'work' || value === 'study'
}

function defaultSyncMetadata(
  taskId: string,
  syncStatus: TaskSyncStatus,
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

function upsertSyncMetadata(
  syncMetadata: TaskSyncMetadata[],
  taskId: string,
  syncStatus: TaskSyncStatus,
): TaskSyncMetadata[] {
  const existing = syncMetadata.find((item) => item.taskId === taskId)
  const next = existing
    ? {
        ...existing,
        syncStatus,
        lastSyncError: null,
      }
    : defaultSyncMetadata(taskId, syncStatus)

  return [next, ...syncMetadata.filter((item) => item.taskId !== taskId)]
}

export function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'hydrate':
      return action.state
    case 'add': {
      if (!action.title.trim()) return state
      const t = nowIso()
      const task: Task = {
        schemaVersion: TASK_SCHEMA_VERSION,
        id: crypto.randomUUID(),
        userId: '11111111-1111-1111-1111-111111111111',
        title: action.title.trim(),
        note: action.note.trim(),
        dueDate: action.dueDate,
        priority: action.priority,
        category: action.category,
        completed: false,
        completedAt: null,
        createdAt: t,
        updatedAt: t,
        deletedAt: null,
        createdByDeviceId: state.deviceId,
        updatedByDeviceId: state.deviceId,
      }
      return {
        ...state,
        tasks: [task, ...state.tasks],
        syncMetadata: upsertSyncMetadata(
          state.syncMetadata,
          task.id,
          'pending-upsert',
        ),
      }
    }
    case 'update': {
      const updatedAt = nowIso()
      let found = false
      const tasks = state.tasks.map((x) => {
        if (x.id !== action.id) return x
        found = true
        return {
          ...x,
          ...action.patch,
          updatedAt,
          updatedByDeviceId: state.deviceId,
        }
      })
      if (!found) return state
      return {
        ...state,
        tasks,
        syncMetadata: upsertSyncMetadata(
          state.syncMetadata,
          action.id,
          'pending-upsert',
        ),
      }
    }
    case 'delete': {
      const deletedAt = nowIso()
      let found = false
      const tasks = state.tasks.map((x) => {
        if (x.id !== action.id) return x
        found = true
        return {
          ...x,
          deletedAt,
          updatedAt: deletedAt,
          updatedByDeviceId: state.deviceId,
        }
      })
      if (!found) return state
      return {
        ...state,
        tasks,
        syncMetadata: upsertSyncMetadata(
          state.syncMetadata,
          action.id,
          'pending-delete',
        ),
      }
    }
    case 'toggleComplete': {
      const completedAt = nowIso()
      let found = false
      const tasks = state.tasks.map((x) => {
        if (x.id !== action.id) return x
        found = true
        const completed = !x.completed
        return {
          ...x,
          completed,
          completedAt: completed ? completedAt : null,
          updatedAt: completedAt,
          updatedByDeviceId: state.deviceId,
        }
      })
      if (!found) return state
      return {
        ...state,
        tasks,
        syncMetadata: upsertSyncMetadata(
          state.syncMetadata,
          action.id,
          'pending-upsert',
        ),
      }
    }
    case 'setUi':
      return { ...state, ui: { ...state.ui, ...action.patch } }
    default:
      return state
  }
}

const SECTIONS: Section[] = ['today', 'upcoming', 'completed']
const sortOrders = new Set<string>(SORT_ORDERS)

function normalizeTask(raw: Partial<Task>, deviceId: string): Task | null {
  if (!isUuid(raw.id)) return null
  if (typeof raw.title !== 'string') return null

  const title = raw.title.trim()
  if (!title) return null
  if (!isIsoTimestamp(raw.createdAt)) return null

  const createdAt = raw.createdAt
  const updatedAt = isIsoTimestamp(raw.updatedAt) ? raw.updatedAt : createdAt
  const completedAt = normalizeOptionalTimestamp(raw.completedAt)
  const completed = raw.completed === true && completedAt !== null

  return {
    schemaVersion: normalizeSchemaVersion(raw.schemaVersion),
    id: raw.id,
    userId: typeof raw.userId === 'string' ? raw.userId : null,
    title,
    note: typeof raw.note === 'string' ? raw.note : '',
    dueDate: normalizeLocalDate(raw.dueDate),
    priority:
      raw.priority === 'low' || raw.priority === 'medium' || raw.priority === 'high'
        ? raw.priority
        : 'medium',
    category:
      raw.category === 'personal' ||
      raw.category === 'work' ||
      raw.category === 'study'
        ? raw.category
        : 'personal',
    completed,
    completedAt: completed ? completedAt : null,
    createdAt,
    updatedAt,
    deletedAt: normalizeOptionalTimestamp(raw.deletedAt),
    createdByDeviceId: isUuid(raw.createdByDeviceId)
      ? raw.createdByDeviceId
      : deviceId,
    updatedByDeviceId: isUuid(raw.updatedByDeviceId)
      ? raw.updatedByDeviceId
      : deviceId,
  }
}

function normalizeSyncMetadata(
  raw: Partial<TaskSyncMetadata>,
  taskId: string,
): TaskSyncMetadata {
  const syncStatus: TaskSyncStatus =
    raw.syncStatus === 'pending-delete' ||
    raw.syncStatus === 'synced' ||
    raw.syncStatus === 'error'
      ? raw.syncStatus
      : 'pending-upsert'

  return {
    taskId,
    ownerUserId: typeof raw.ownerUserId === 'string' ? raw.ownerUserId : null,
    syncStatus,
    lastSyncedAt: normalizeOptionalTimestamp(raw.lastSyncedAt),
    lastKnownServerUpdatedAt: isIsoTimestamp(raw.lastKnownServerUpdatedAt)
      ? raw.lastKnownServerUpdatedAt
      : null,
    lastSyncError:
      typeof raw.lastSyncError === 'string' ? raw.lastSyncError : null,
  }
}

export function mergeHydrated(input: {
  deviceId: string
  taskData: TaskDataState | null
  ui: Partial<UiState> | null
}): State {
  const { deviceId, taskData, ui: rawUi } = input
  const rawTasks = Array.isArray(taskData?.tasks) ? taskData.tasks : []
  const tasks = rawTasks
    .map((task) => normalizeTask(task, deviceId))
    .filter((task): task is Task => task !== null)

  const syncMetadataByTaskId = new Map<string, TaskSyncMetadata>()
  for (const raw of Array.isArray(taskData?.syncMetadata)
    ? taskData.syncMetadata
    : []) {
    if (!isUuid(raw?.taskId)) continue
    syncMetadataByTaskId.set(
      raw.taskId,
      normalizeSyncMetadata(raw, raw.taskId),
    )
  }

  const syncMetadata = tasks.map((task) =>
    syncMetadataByTaskId.get(task.id) ??
    defaultSyncMetadata(
      task.id,
      task.deletedAt ? 'pending-delete' : 'pending-upsert',
    ),
  )

  if (!taskData && !rawUi) {
    return {
      deviceId,
      tasks: [],
      syncMetadata: [],
      ui: { ...defaultUi },
    }
  }

  const sec = rawUi?.section
  const section = SECTIONS.includes(sec as Section) ? (sec as Section) : 'today'
  const sortOrder = sortOrders.has(rawUi?.sortOrder ?? '')
    ? (rawUi?.sortOrder as UiState['sortOrder'])
    : defaultUi.sortOrder
  return {
    deviceId,
    tasks,
    syncMetadata,
    ui: {
      ...defaultUi,
      ...rawUi,
      section,
      search: typeof rawUi?.search === 'string' ? rawUi.search : '',
      statusFilter: isStatusFilter(rawUi?.statusFilter)
        ? rawUi.statusFilter
        : 'all',
      priorityFilter: isPriorityFilter(rawUi?.priorityFilter)
        ? rawUi.priorityFilter
        : 'all',
      categoryFilter: isCategoryFilter(rawUi?.categoryFilter)
        ? rawUi.categoryFilter
        : 'all',
      sortOrder,
    },
  }
}
