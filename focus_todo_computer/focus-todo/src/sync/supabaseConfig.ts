export interface SupabaseConfig {
  url: string | null
  anonKey: string | null
}

function normalizeConfigValue(value: string | null | undefined): string | null {
  if (!value) return null
  const trimmed = value.trim()
  return trimmed ? trimmed : null
}

export const SUPABASE_URL = normalizeConfigValue(
  import.meta.env.VITE_SUPABASE_URL,
)

export const SUPABASE_ANON_KEY = normalizeConfigValue(
  import.meta.env.VITE_SUPABASE_ANON_KEY,
)

export function getSupabaseConfig(): SupabaseConfig {
  return {
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  }
}

export function hasSupabaseConfig(config: SupabaseConfig = getSupabaseConfig()): boolean {
  return Boolean(config.url && config.anonKey)
}
