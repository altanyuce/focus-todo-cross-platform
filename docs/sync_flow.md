# Sync Flow

## Purpose

This document defines how task lifecycle and sync state should behave before and after version-1 sync is introduced.

It assumes the current local-first model remains in place and sync is added around it.

## Before Sync: Current Task Lifecycle

### Boot and hydration

1. Read local `deviceId`.
2. Read local persisted task snapshot.
3. Read local UI state separately.
4. Normalize persisted task records.
5. Recreate missing sync metadata:
   - active task -> `pending-upsert`
   - deleted task -> `pending-delete`
6. Render from local state immediately.

### Local create

1. Generate `id`.
2. Set:
   - `schemaVersion` once that field is added
   - `createdAt`
   - `updatedAt`
   - `createdByDeviceId`
   - `updatedByDeviceId`
   - `completed = false`
   - `completedAt = null`
   - `deletedAt = null`
3. Insert task into local state.
4. Mark sync metadata as `pending-upsert`.
5. Persist locally.

### Local update

1. Mutate allowed task fields.
2. Set `updatedAt`.
3. Set `updatedByDeviceId`.
4. Mark sync metadata as `pending-upsert`.
5. Persist locally.

### Local complete

1. Set `completed = true`.
2. Set `completedAt = now`.
3. Set `updatedAt = completedAt`.
4. Set `updatedByDeviceId`.
5. Mark sync metadata as `pending-upsert`.
6. Persist locally.

### Local reopen

1. Set `completed = false`.
2. Set `completedAt = null`.
3. Set `updatedAt = now`.
4. Set `updatedByDeviceId`.
5. Mark sync metadata as `pending-upsert`.
6. Persist locally.

### Local delete

1. Set `deletedAt = now`.
2. Set `updatedAt = deletedAt`.
3. Set `updatedByDeviceId`.
4. Mark sync metadata as `pending-delete`.
5. Persist locally.
6. Hide from visible task lists, but keep the tombstone locally.

## After Sync Is Introduced

The core rule does not change:

- local mutation happens first
- persistence happens locally first
- sync happens afterward

Sync must wrap the current lifecycle, not replace it.

## Pending State Semantics

### `pending-upsert`

Behavior:

- Means the next outbound attempt should send the full canonical task payload.
- Any create, edit, complete, or reopen sets this state.
- If the task was previously `error`, the new local mutation clears the error and returns it to `pending-upsert`.
- If the task was previously `synced`, the local mutation moves it back to `pending-upsert`.

### `pending-delete`

Behavior:

- Means the next outbound attempt should send the task as a tombstone payload.
- This state replaces `pending-upsert`; a task cannot be pending both.
- A tombstoned task stays stored locally until explicit purge logic exists.
- If a sync attempt fails, it can move to `error` but must still be retried as a delete.

## Outbound Sync Flow

### Selection

The sync coordinator selects tasks where local sync metadata is:

- `pending-upsert`
- `pending-delete`
- optionally `error` when retrying

### Order

Version 1 should keep outbound execution simple:

1. Read the latest local state after hydration.
2. Build a list of pending tasks.
3. Send each task as a full canonical task payload.
4. Apply responses one task at a time.

No operation log is required in version 1 because the current apps already retain full task state plus tombstones.

### Success handling

On successful outbound apply:

1. Keep the winning local task body exactly as confirmed by merge rules.
2. Set metadata to:
   - `syncStatus = synced`
   - `lastSyncedAt = now` (local-only)
   - `lastKnownServerUpdatedAt = confirmed remote updatedAt`
   - `lastSyncError = null`

### Failure handling

On outbound failure:

1. Keep the local task body unchanged.
2. Set:
   - `syncStatus = error`
   - `lastSyncError = reason`
3. Do not hide or remove the task because of sync failure.
4. Retry later.

## Inbound Sync Flow

Inbound sync applies remote tasks into already-hydrated local state.

### Inbound apply steps

1. Validate the remote task against the canonical contract.
2. Normalize safe fields if allowed by contract.
3. Drop invalid tasks that cannot be safely repaired.
4. Look up the local task by `id`.
5. If local task does not exist:
   - insert the remote task
   - create local sync metadata as `synced`
6. If local task exists:
   - compare local and remote using version-1 conflict policy
   - write back the winning task
   - update local sync metadata accordingly

### Inbound metadata handling

If the remote record wins:

- local task becomes the remote winning version
- local metadata becomes `synced`
- `lastKnownServerUpdatedAt` becomes remote `updatedAt`
- `lastSyncError` is cleared

If the local record wins:

- keep local task body
- keep it pending outbound:
  - `pending-upsert` for active records
  - `pending-delete` for tombstones

## Create, Update, Complete, Reopen, Delete With Sync

### Create

1. Create locally.
2. Mark `pending-upsert`.
3. Sync later.
4. If remote accepts it unchanged, mark `synced`.
5. If remote returns a newer winning record, apply remote via merge.

### Update

1. Update locally.
2. Mark `pending-upsert`.
3. Sync later.
4. If remote has an older version, local update should eventually win.
5. If remote has a newer version, remote may overwrite local by LWW.

### Complete

1. Complete locally.
2. Mark `pending-upsert`.
3. Sync later as a normal task upsert.
4. Conflict resolution is based on `updatedAt`, not on `completed` directly.

### Reopen

1. Reopen locally.
2. Clear `completedAt`.
3. Mark `pending-upsert`.
4. Sync later as a normal task upsert.
5. A newer remote completion can still win.

### Delete

1. Soft delete locally.
2. Mark `pending-delete`.
3. Sync later as a tombstone payload.
4. Deleted task remains hidden locally.
5. Tombstone remains until purge policy exists.

## Boot and Hydration Flow With Future Sync

Version 1 boot flow should be:

1. Load `deviceId`.
2. Load local task snapshot.
3. Load local UI state.
4. Normalize and render local task state.
5. Start sync coordinator after local hydration finishes.
6. Run one foreground sync pass.
7. Merge inbound remote records into local state.
8. Persist resulting local state.

Important rule:

- Sync must not block first render.

## Retry and Error Flow

Version 1 should keep retry behavior small and deterministic:

### When a task enters `error`

- outbound request failed
- server rejected a valid local task in a retryable way
- task-level apply failed after transport succeeded

### What the client should do

- keep the task visible according to its local state
- preserve the task body
- store `lastSyncError`
- retry on the next sync trigger

### Retry triggers

Recommended version-1 triggers:

- app boot after hydration
- app foreground/resume
- explicit manual retry or sync action if one is added

Deferred from version 1:

- aggressive background retry
- complex exponential backoff orchestration
- per-task retry scheduling UI

## Offline-First Expectations

- All task actions must continue to work with no network.
- Local persistence remains the source of immediate UX truth.
- Sync is eventual, not blocking.
- A task may remain `pending-upsert`, `pending-delete`, or `error` for a long time without breaking normal task use.
- Deleted tasks stay hidden even when outbound delete has not yet been acknowledged.
- The client must be able to fully recover from app restart using only local persisted task state plus metadata.

## Version-1 Flow Summary

1. Hydrate local state first.
2. Let the user work locally immediately.
3. Mark local changes as `pending-upsert` or `pending-delete`.
4. Sync after hydration, not instead of hydration.
5. Resolve conflicts with deterministic LWW.
6. Keep tombstones.
7. Retry failures without blocking local use.
