export type Section = 'today' | 'upcoming' | 'completed'

export type Priority = 'low' | 'medium' | 'high'

export type Category = 'personal' | 'work' | 'study'

export type StatusFilter = 'all' | 'active' | 'done'

export type TaskSyncStatus =
  | 'pending-upsert'
  | 'pending-delete'
  | 'synced'
  | 'error'

export const SORT_ORDERS = [
  'default',
  'due-date-desc',
  'due-date-asc',
  'priority-desc',
  'priority-asc',
  'title-asc',
  'title-desc',
  'created-desc',
  'created-asc',
] as const

export type SortOrder = (typeof SORT_ORDERS)[number]

export type PriorityFilter = 'all' | Priority

export type CategoryFilter = 'all' | Category

export const CURRENT_TASK_SCHEMA_VERSION = 1

export interface Task {
  schemaVersion: number
  id: string
  userId?: string | null
  title: string
  note: string
  dueDate: string | null
  priority: Priority
  category: Category
  completed: boolean
  completedAt: string | null
  createdAt: string
  updatedAt: string
  deletedAt: string | null
  createdByDeviceId: string
  updatedByDeviceId: string
}

export interface TaskSyncMetadata {
  taskId: string
  ownerUserId: string | null
  syncStatus: TaskSyncStatus
  lastSyncedAt: string | null
  lastKnownServerUpdatedAt: string | null
  lastSyncError: string | null
}

export interface UiState {
  section: Section
  search: string
  statusFilter: StatusFilter
  priorityFilter: PriorityFilter
  categoryFilter: CategoryFilter
  sortOrder: SortOrder
}

export interface TaskDataState {
  tasks: Task[]
  syncMetadata: TaskSyncMetadata[]
}

export type TaskUpdatePatch = Partial<
  Pick<
    Task,
    | 'title'
    | 'note'
    | 'dueDate'
    | 'priority'
    | 'category'
    | 'completed'
    | 'completedAt'
  >
>
