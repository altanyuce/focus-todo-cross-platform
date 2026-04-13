# Sync Architecture

## Purpose

This document defines the minimum architecture needed to move the current local-first Desktop and Mobile clients toward a safe version-1 task sync implementation.

It is intentionally practical:

- It reflects the current codebase as it exists today.
- It does not introduce backend, auth, or transport implementation.
- It keeps version 1 small so actual sync work can start without a large local storage rewrite.

## Sync Goals

- Sync tasks, and only tasks, across Desktop and Mobile.
- Preserve the current local-first UX: local create/edit/complete/delete must continue to work offline.
- Keep both clients behaviorally aligned with the task contract.
- Make sync deterministic enough that the same task converges to the same final state on both clients.
- Reuse the existing local mutation metadata (`pending-upsert`, `pending-delete`, `synced`, `error`) instead of inventing a larger queue system first.
- Allow sync to be introduced without blocking app boot or first render.

## Non-Goals

- No sync engine implementation in this phase.
- No API client, server code, or auth implementation.
- No realtime sync.
- No multi-user collaboration.
- No sync of UI state, filters, sort order, theme, language, or other presentation preferences.
- No large storage split or storage technology migration before the first prototype.
- No conflict UI in version 1.
- No tombstone purge policy in version 1.

## Current Local-First Architecture

### Shared behavior already present on both clients

- Each app generates and persists a stable local `deviceId`.
- Each app hydrates local task state first.
- Each app persists task records and sync metadata together under `focus-todo-task-data-v2`.
- Each app persists UI state separately under `focus-todo-ui-state-v1`.
- Each app can read a legacy combined state shape and normalize it into the new local shape.
- Each app normalizes task records on hydration and drops invalid tasks.
- Each app sets sync metadata for local changes:
  - create/update/complete/reopen -> `pending-upsert`
  - delete -> `pending-delete`
- Soft delete is already the local deletion behavior through `deletedAt`.
- Deleted tasks stay stored locally but are hidden from visible task lists.

### Desktop current flow

1. `TodoProvider` loads `deviceId`, task data, and UI state during bootstrap.
2. `mergeHydrated(...)` normalizes persisted records and creates default sync metadata for tasks that do not already have it.
3. UI actions dispatch reducer mutations.
4. The reducer mutates in-memory task state and sync metadata together.
5. A debounced persistence effect writes task data and UI state back to local storage.

### Mobile current flow

1. `appStartupProvider` initializes preferences and then task state.
2. `TasksNotifier.initialize()` loads `deviceId`, task data, and UI state.
3. `_buildHydratedState(...)` normalizes persisted records and creates default sync metadata for tasks that do not already have it.
4. UI actions call notifier methods.
5. The notifier mutates in-memory task state and sync metadata together.
6. Persistence is written back asynchronously to local storage.

## Canonical Syncable Entity Boundaries

### Syncable entity in version 1

Only `Task` is syncable.

The canonical sync payload for a task should be:

- `schemaVersion`
- `id`
- `title`
- `completed`
- `createdAt`
- `updatedAt`
- `createdByDeviceId`
- `updatedByDeviceId`
- `note`
- `dueDate`
- `priority`
- `category`
- `completedAt`
- `deletedAt`

### Important current-code reality

Current Desktop and Mobile task models do not yet store `schemaVersion` on each task, even though the task contract defines it.

Pragmatic decision:

- `schemaVersion` should be added before the first real sync prototype starts.
- This is a small contract-alignment patch, not a storage refactor.
- It should default to `1` for all existing locally normalized tasks.

## What Stays Local-Only

These values must remain local-only and must not be part of the synced task payload:

- Task sync metadata
  - `syncStatus`
  - `lastSyncedAt`
  - `lastSyncError`
  - `lastKnownServerUpdatedAt`
  - `ownerUserId`
- UI state
  - section
  - search query
  - filters
  - sort order
- App preferences
  - theme
  - language
  - any other per-device preference
- Device identity storage itself
- Any future local caches, retry bookkeeping, or diagnostics

## What Sync Metadata Means

The existing sync metadata is already sufficient for a small version-1 sync coordinator.

### `pending-upsert`

Meaning:

- The local task record changed and must be sent outbound as the full canonical task payload.

Produced by:

- create
- edit
- complete
- reopen
- local conflict resolution that keeps the local version as the winner

### `pending-delete`

Meaning:

- The local task record is a tombstone and must be sent outbound as a delete-shaped task payload with `deletedAt` populated.

Produced by:

- local soft delete
- local conflict resolution that keeps the local tombstone as the winner

### `synced`

Meaning:

- The local record matches the last server-confirmed canonical task state known to the client.

### `error`

Meaning:

- The last outbound attempt for this task failed and should be retried later.

### Supporting metadata fields

- `lastSyncedAt`
  - local-only timestamp recording when the client last completed a successful sync for this task
- `lastKnownServerUpdatedAt`
  - local-only cache of the server-confirmed `updatedAt` for the current synced task version
- `lastSyncError`
  - last task-level sync error message for retry and diagnostics
- `ownerUserId`
  - local-only scoping field for future authenticated sync; safe to leave `null` until auth exists

## Current Contract/Code Gaps That Matter For Sync

### `schemaVersion`

- Contract says every task has it.
- Current clients do not persist it yet.
- Decision: add it before sync prototype.

### `priority` and `category`

- Contract allows arbitrary strings or `null`.
- Current clients use enum-like product values only.
- Decision: keep existing product values for version 1 local UX and initial sync prototype.
- At the sync boundary, treat them as string fields, not as future-proof enums owned by the server.
- Flexible custom values are deferred until after version 1 because both clients currently normalize unknown values back into built-in options.

### Physical storage separation

- Contract says tasks, sync metadata, UI state, and device ID should be separate storage concerns.
- Current code already separates UI state and device ID, but tasks and sync metadata are co-persisted in one `TaskDataState` envelope.
- Decision: keep task records and sync metadata in one persisted local envelope for now.
- Reason: changing storage layout now adds migration risk but does not materially reduce sync risk for version 1.

### Timestamp ownership

- Current clients already stamp local task mutations with `createdAt`, `updatedAt`, `completedAt`, and `deletedAt`.
- Decision for version 1: keep the current client-generated task timestamps as the sync ordering inputs.
- The first sync prototype should not introduce a second revision system, server-issued version counter, or timestamp rewrite layer.
- The server side, when it exists, should either preserve those canonical task timestamps or return a canonical task record that remains compatible with the documented LWW rule.

## Recommended Future Sync Layers

The first real sync implementation should introduce thin layers, not a full framework:

1. Canonical task mapper
   - Maps local task models to and from the contract payload.
   - Owns `schemaVersion` defaults and validation.

2. Sync state reader
   - Reads tasks plus local sync metadata.
   - Selects outbound candidates from `pending-upsert`, `pending-delete`, and optionally `error`.

3. Outbound sync executor
   - Sends canonical task payloads.
   - Applies success or failure metadata updates.

4. Inbound merge engine
   - Compares local and remote versions of the same task using the documented LWW policy.
   - Writes the winning task back locally.

5. Sync coordinator
   - Triggers sync on boot completion, app resume/foreground, and explicit retry or manual sync.
   - Never blocks initial local hydration.

6. Diagnostics
   - Logs invalid payload drops, conflict outcomes, and retry failures.

## Recommended Sequencing From Local-First To Sync-Enabled

### Phase 0: preparation hardening

- Add `schemaVersion` to both local task models and normalization code.
- Freeze the version-1 canonical task payload.
- Freeze the version-1 conflict policy.
- Freeze the meaning of `pending-upsert`, `pending-delete`, `synced`, and `error`.

### Phase 1: client sync foundation

- Add pure shared logic per client for:
  - canonical payload mapping
  - outbound candidate selection
  - inbound merge
  - sync metadata transitions
- Keep transport behind an interface.
- Do not add background jobs yet.

### Phase 2: first sync prototype

- Sync tasks only.
- Run a one-shot foreground sync after hydration.
- Support outbound create/update/complete/reopen/delete.
- Support inbound remote create/update/delete.
- Apply deterministic LWW conflict resolution.
- Mark successful tasks as `synced`.
- Mark failed tasks as `error`.

### Phase 3: post-prototype hardening

- Add better retry policy.
- Add metrics and richer diagnostics.
- Decide tombstone retention and purge.
- Revisit flexible priority/category handling if product needs it.
- Revisit physical storage split only if real sync behavior shows a concrete benefit.

## Version-1 Architecture Decisions

- `schemaVersion`: add now, before the first sync prototype.
- `priority` and `category`: keep enum-like product values in version 1; treat them as plain string fields at the sync boundary; defer custom values.
- task data vs sync metadata storage: keep one local envelope for now.
- tombstone purge: defer.
- minimum viable sync prototype scope:
  - single entity type: tasks
  - local-first hydration first
  - one-shot foreground sync after hydration
  - outbound upsert/delete
  - inbound apply and LWW merge
  - no realtime
  - no background service
  - no sync for UI state or preferences
  - no custom conflict UI
