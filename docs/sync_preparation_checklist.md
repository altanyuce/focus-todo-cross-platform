# Sync Preparation Checklist

## Already Ready

- Desktop and Mobile already share the same local-first task shape in practice:
  - `id`
  - `title`
  - `note`
  - `dueDate`
  - `priority`
  - `category`
  - `completed`
  - `completedAt`
  - `createdAt`
  - `updatedAt`
  - `deletedAt`
  - `createdByDeviceId`
  - `updatedByDeviceId`
- Both clients already generate and persist stable per-device IDs.
- Both clients already persist tasks locally and hydrate from them first.
- Both clients already soft-delete through `deletedAt`.
- Both clients already maintain local sync metadata states:
  - `pending-upsert`
  - `pending-delete`
  - `synced`
  - `error`
- Both clients already normalize persisted data and can recover from legacy local state.
- Both clients already keep UI state separate from task state.
- Both clients already filter deleted tasks out of visible task lists.

## Decisions Closed Now

These decisions are now fixed for version 1 and should not be reopened before the first prototype unless product requirements change:

- `schemaVersion`
  - decision: add now, before the first sync prototype
- `priority` and `category`
  - decision: keep existing enum-like product values in version 1
  - sync boundary still treats them as strings
  - flexible custom values are deferred
- task records vs sync metadata storage
  - decision: keep one local persisted envelope for now
- tombstone purge
  - decision: defer until after first sync prototype
- minimum viable sync prototype scope
  - decision: tasks only, one-shot foreground sync after hydration, deterministic LWW, no realtime, no background service, no UI-state sync

## Still Must Be Decided

These decisions can wait until backend-facing sync work actually starts. None of them should block the first client-side sync foundation work:

- whether the first shipped sync entry point is automatic only, manual only, or both
- exact platform-specific foreground/resume trigger behavior
- exact server acknowledgment shape:
  - full canonical task echo
  - accepted task plus revision metadata
- tombstone retention window once server behavior exists
- whether failed sync state needs a visible user-facing indicator in version 1 or can stay internal

## Must Be Implemented Before First Sync Prototype

### Contract alignment

- Add `schemaVersion` to both clients' local task models.
- Update local task normalization so old tasks are upgraded to `schemaVersion = 1`.
- Freeze the exact canonical task payload and keep it identical across Desktop and Mobile.
- Keep client-generated task timestamps as the version-1 ordering inputs.

### Shared sync semantics per client

- Implement a canonical payload mapper.
- Implement local task-to-sync-candidate selection from existing metadata.
- Implement the exact conflict policy in code.
- Implement sync metadata transitions for:
  - success
  - retryable failure
  - remote-wins merge
  - local-wins requeue

### Lifecycle and integration

- Add a sync coordinator entry point that runs only after local hydration.
- Define version-1 sync triggers:
  - post-hydration boot
  - app foreground/resume
  - manual retry if exposed
- Ensure sync never blocks local render.

### Validation and diagnostics

- Validate inbound task payloads against the task contract.
- Log or surface invalid payload drops in diagnostics.
- Record last task-level sync failure in `lastSyncError`.

## Can Wait Until After First Sync Prototype

- auth wiring
- background sync worker
- realtime updates
- batch optimization
- pagination
- conflict UI
- flexible custom priority/category values
- tombstone purge
- physical storage split between task records and sync metadata
- metrics dashboards and richer observability tooling

## Strict Ordered Roadmap

1. Add `schemaVersion` to Desktop and Mobile task models, serializers, and normalization.
2. Freeze the version-1 canonical task payload in code comments or dedicated mapping modules.
3. Implement pure client-side conflict resolution logic from `docs/conflict_policy.md`.
4. Implement pure client-side outbound candidate selection based on existing sync metadata.
5. Implement pure client-side metadata transition helpers for success, failure, and merge outcomes.
6. Introduce a sync coordinator interface that runs after hydration and can execute one foreground sync pass.
7. Wire the coordinator into Desktop boot lifecycle without blocking first render.
8. Wire the coordinator into Mobile boot and foreground lifecycle without blocking local UX.
9. Add task-level retry behavior for `error` records on the next sync trigger.
10. Test cross-platform convergence using the same task fixtures and conflict scenarios on both clients.
11. Only after the above is stable, connect the coordinator to a real transport and backend.

## Minimum Viable Sync Prototype Scope

The first real sync prototype should do exactly this:

- sync tasks only
- use full task payloads, not patches
- support create/update/complete/reopen/delete
- represent delete as a tombstone task payload
- hydrate local state first
- run one foreground sync pass after hydration
- apply inbound tasks with deterministic LWW
- keep failed records locally with `error`

It should explicitly not do this:

- sync UI state
- sync preferences
- background daemon work
- realtime subscriptions
- custom conflict resolution UI
- tombstone purge
- flexible category/priority product expansion

## Practical Risks To Watch During Implementation

- Current code and contract disagree on `schemaVersion`; this must be closed first.
- Current code strongly types `priority` and `category`; accepting unknown remote values too early will create churn.
- Contract says separate storage concerns, but the code currently co-persists tasks and sync metadata; avoid rewriting storage before it proves necessary.
- LWW depends on timestamp quality; inconsistent timestamp handling across clients will cause divergence.
- Tombstones are safe for convergence, but without purge they will accumulate; that is acceptable in version 1, but it is still a future maintenance concern.
