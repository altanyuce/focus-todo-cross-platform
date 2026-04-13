import {
  getSupabaseConfig,
  hasSupabaseConfig,
  type SupabaseConfig,
} from './supabaseConfig'
import { pullSupabaseTodos, writeSupabaseTodo } from './supabaseTodoSync'
import type { CanonicalTask } from './canonicalTaskMapper'
import type { SyncTransport, SyncWriteResult } from './syncTransport'

export class SupabaseTransportNotConfiguredError extends Error {
  constructor() {
    super('Supabase sync is not configured')
    this.name = 'SupabaseTransportNotConfiguredError'
  }
}

export class SupabaseSyncTransport implements SyncTransport {
  private readonly configured: boolean

  constructor(config: SupabaseConfig = getSupabaseConfig()) {
    this.configured = hasSupabaseConfig(config)
  }

  isConfigured(): boolean {
    return this.configured
  }

  async writeTask(
    task: CanonicalTask,
    expectedUpdatedAt: string | null,
  ): Promise<SyncWriteResult> {
    if (!this.configured) {
      throw new SupabaseTransportNotConfiguredError()
    }

    return writeSupabaseTodo(task, expectedUpdatedAt)
  }

  async pullTasks(): Promise<CanonicalTask[]> {
    if (!this.configured) {
      throw new SupabaseTransportNotConfiguredError()
    }

    return pullSupabaseTodos()
  }
}
