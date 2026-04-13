import { supabase } from '../lib/supabase'
import type { CanonicalTask } from './canonicalTaskMapper'
import type { SyncWriteResult } from './syncTransport'

const SUPABASE_TODOS_TABLE = 'todos'
const CANONICAL_COLUMNS = `
  id,
  user_id,
  title,
  note,
  due_date,
  priority,
  category,
  completed,
  completed_at,
  created_at,
  updated_at,
  deleted_at,
  created_by_device_id,
  updated_by_device_id,
  schema_version
`

interface RpcWriteRow {
  applied: boolean
  conflict: boolean
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

function isCanonicalTask(value: unknown): value is CanonicalTask {
  if (!value || typeof value !== 'object') return false

  const row = value as Record<string, unknown>
  return (
    typeof row.id === 'string' &&
    (row.user_id === null || typeof row.user_id === 'string') &&
    typeof row.title === 'string' &&
    typeof row.note === 'string' &&
    (row.due_date === null || typeof row.due_date === 'string') &&
    typeof row.priority === 'string' &&
    typeof row.category === 'string' &&
    typeof row.completed === 'boolean' &&
    (row.completed_at === null || typeof row.completed_at === 'string') &&
    typeof row.created_at === 'string' &&
    typeof row.updated_at === 'string' &&
    (row.deleted_at === null || typeof row.deleted_at === 'string') &&
    typeof row.created_by_device_id === 'string' &&
    typeof row.updated_by_device_id === 'string' &&
    Number.isInteger(row.schema_version)
  )
}

function isRpcWriteRow(value: unknown): value is RpcWriteRow {
  if (!isCanonicalTask(value)) return false

  const row = value as unknown as Record<string, unknown>
  return typeof row.applied === 'boolean' && typeof row.conflict === 'boolean'
}

function getRpcWriteRow(data: unknown): RpcWriteRow | null {
  const candidate = Array.isArray(data) ? data[0] : data
  return isRpcWriteRow(candidate) ? candidate : null
}

function toCanonicalTask(row: RpcWriteRow): CanonicalTask {
  return {
    id: row.id,
    user_id: row.user_id,
    title: row.title,
    note: row.note,
    due_date: row.due_date,
    priority: row.priority,
    category: row.category,
    completed: row.completed,
    completed_at: row.completed_at,
    created_at: row.created_at,
    updated_at: row.updated_at,
    deleted_at: row.deleted_at,
    created_by_device_id: row.created_by_device_id,
    updated_by_device_id: row.updated_by_device_id,
    schema_version: row.schema_version,
  }
}

export async function writeSupabaseTodo(
  task: CanonicalTask,
  expectedUpdatedAt: string | null,
): Promise<SyncWriteResult> {
  const { data, error } = await supabase.rpc('upsert_todo_if_version_matches', {
    p_id: task.id,
    p_user_id: task.user_id,
    p_title: task.title,
    p_note: task.note,
    p_due_date: task.due_date,
    p_priority: task.priority,
    p_category: task.category,
    p_completed: task.completed,
    p_completed_at: task.completed_at,
    p_created_at: task.created_at,
    p_updated_at: task.updated_at,
    p_deleted_at: task.deleted_at,
    p_created_by_device_id: task.created_by_device_id,
    p_updated_by_device_id: task.updated_by_device_id,
    p_schema_version: task.schema_version,
    p_expected_updated_at: expectedUpdatedAt,
  })

  if (error) {
    throw new Error(`Supabase write failed: ${error.message}`)
  }

  const rpcRow = getRpcWriteRow(data)
  const remoteTask = rpcRow ? toCanonicalTask(rpcRow) : null

  return {
    applied: rpcRow?.applied === true,
    conflict: rpcRow?.conflict === true,
    remoteTask,
    rowUpdatedAt: remoteTask?.updated_at ?? null,
  }
}

export async function pullSupabaseTodos(): Promise<CanonicalTask[]> {
  const { data, error } = await supabase
    .from(SUPABASE_TODOS_TABLE)
    .select(CANONICAL_COLUMNS)
    .order('updated_at', { ascending: true })
    .order('id', { ascending: true })

  if (error) {
    throw new Error(`Supabase pull failed: ${error.message}`)
  }

  return Array.isArray(data) ? data.filter(isCanonicalTask) : []
}
