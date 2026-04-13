import type { CanonicalTask } from './canonicalTaskMapper'
import { FakeSyncTransport } from './fakeSyncTransport'
import { SupabaseSyncTransport } from './supabaseSyncTransport'
import type { SyncTransport } from './syncTransport'

export type SyncTransportMode = 'fake' | 'supabase'

export class SyncTransportRegistry {
  private mode: SyncTransportMode = 'fake'
  private readonly fakeTransport = new FakeSyncTransport()
  private readonly supabaseTransport = new SupabaseSyncTransport()

  getMode(): SyncTransportMode {
    return this.mode
  }

  setMode(mode: SyncTransportMode): void {
    this.mode = mode
  }

  getTransport(): SyncTransport {
    return this.mode === 'supabase'
      ? this.supabaseTransport
      : this.fakeTransport
  }

  getRemoteSnapshot(): CanonicalTask[] {
    return this.mode === 'fake' ? this.fakeTransport.snapshot() : []
  }
}
