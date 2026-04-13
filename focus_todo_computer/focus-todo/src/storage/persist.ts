import { loadLegacyState } from './legacyState'

/**
 * Backward-compatible legacy snapshot loader.
 * New code should use the split task/ui storage modules instead.
 */
export function loadState() {
  return loadLegacyState()
}
