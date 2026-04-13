import {
  CURRENT_TASK_SCHEMA_VERSION,
  type Category,
  type Priority,
  type Task,
} from '../types/task'

export interface CanonicalTask {
  id: string
  user_id: string | null
  title: string
  note: string
  due_date: string | null
  priority: string
  category: string
  completed: boolean
  completed_at: string | null
  created_at: string
  updated_at: string
  deleted_at: string | null
  created_by_device_id: string
  updated_by_device_id: string
  schema_version: number
}

function normalizePriority(value: string | null): Priority {
  switch (value) {
    case 'low':
      return 'low'
    case 'high':
      return 'high'
    case 'medium':
    default:
      return 'medium'
  }
}

function normalizeCategory(value: string | null): Category {
  switch (value) {
    case 'work':
      return 'work'
    case 'study':
      return 'study'
    case 'personal':
    default:
      return 'personal'
  }
}

export function toCanonicalTask(localTask: Task): CanonicalTask {
  return {
    id: localTask.id,
    user_id: localTask.userId ?? null,
    title: localTask.title,
    note: localTask.note,
    due_date: localTask.dueDate,
    priority: localTask.priority,
    category: localTask.category,
    completed: localTask.completed,
    completed_at: localTask.completedAt,
    created_at: localTask.createdAt,
    updated_at: localTask.updatedAt,
    deleted_at: localTask.deletedAt,
    created_by_device_id: localTask.createdByDeviceId,
    updated_by_device_id: localTask.updatedByDeviceId,
    schema_version: localTask.schemaVersion,
  }
}

export function fromCanonicalTask(canonicalTask: CanonicalTask): Task {
  return {
    schemaVersion:
      Number.isInteger(canonicalTask.schema_version) &&
      canonicalTask.schema_version > 0
        ? canonicalTask.schema_version
        : CURRENT_TASK_SCHEMA_VERSION,
    id: canonicalTask.id,
    userId: canonicalTask.user_id,
    title: canonicalTask.title,
    note: canonicalTask.note,
    dueDate: canonicalTask.due_date,
    priority: normalizePriority(canonicalTask.priority),
    category: normalizeCategory(canonicalTask.category),
    completed: canonicalTask.completed,
    completedAt: canonicalTask.completed_at,
    createdAt: canonicalTask.created_at,
    updatedAt: canonicalTask.updated_at,
    deletedAt: canonicalTask.deleted_at,
    createdByDeviceId: canonicalTask.created_by_device_id,
    updatedByDeviceId: canonicalTask.updated_by_device_id,
  }
}
