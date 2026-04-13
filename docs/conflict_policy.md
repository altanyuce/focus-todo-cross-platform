# Conflict Policy

## Purpose

This document defines the exact version-1 conflict policy for task sync.

The goal is convergence with minimal complexity. Version 1 intentionally chooses deterministic Last Write Wins (LWW) over richer merge behavior.

## Conflict Assumptions

- Only tasks participate in sync.
- A conflict exists when local and remote both have a record for the same `task.id` and the normalized task bodies differ.
- Clients are local-first, so local state may already include unsynced edits when remote data arrives.
- Deletes are tombstones, not hard deletes.
- Version 1 does not attempt field-level merges.
- Version 1 assumes task timestamps are valid and comparable as UTC instants.

## Version-1 Conflict Resolution Policy

Use record-level LWW for the entire task.

This means:

- choose exactly one winning task record
- write that full winning record locally
- do not merge title from one side and note from the other
- do not keep both versions

## Exact LWW Rule

Given `localTask` and `remoteTask` with the same `id`:

1. Normalize both task records.
2. Compare `updatedAt` as UTC timestamps.
3. The record with the later `updatedAt` wins.
4. If `updatedAt` is equal:
   - a record with `deletedAt != null` wins over a record with `deletedAt == null`
5. If both still tie:
   - compare `updatedByDeviceId` after lowercasing
   - the lexicographically greater device ID wins
6. If both still tie:
   - prefer the remote record and log a conflict anomaly

Step 6 is a deterministic final escape hatch for impossible or buggy duplicate writes. It should be rare.

## Tie-Breaker Rule

The exact tie-breaker in version 1 is:

- `updatedAt` equal
- deleted wins
- if still tied, lexicographically greater `updatedByDeviceId` wins
- if still tied, remote wins

This rule must be applied identically on Desktop and Mobile.

## Tombstone Behavior

- A deleted task is represented by a normal task record with `deletedAt` set.
- Tombstones sync like any other task payload.
- Tombstones stay locally stored in version 1.
- A tombstone hides the task from visible task lists immediately.
- A tombstone can still lose if the competing active record has a strictly later `updatedAt`.
- If `updatedAt` ties, the tombstone wins.

## How The Client Should Behave When Local And Remote Differ

### If the remote record wins

The client should:

1. Replace the full local task body with the remote record.
2. Set sync metadata to `synced`.
3. Set `lastKnownServerUpdatedAt` to remote `updatedAt`.
4. Clear `lastSyncError`.
5. Set `lastSyncedAt` to the local time of successful apply.

### If the local record wins

The client should:

1. Keep the full local task body.
2. Keep the task pending outbound:
   - `pending-upsert` if `deletedAt == null`
   - `pending-delete` if `deletedAt != null`
3. Preserve or refresh retry state as needed.
4. Avoid marking it `synced` until the winning local version is accepted remotely.

## Example Conflict Cases

### Case 1: local edit vs older remote

Local:

- title = "Pay rent today"
- updatedAt = `2026-04-02T10:00:00Z`
- updatedByDeviceId = `bbbb...`

Remote:

- title = "Pay rent"
- updatedAt = `2026-04-02T09:30:00Z`
- updatedByDeviceId = `aaaa...`

Result:

- local wins
- keep local body
- remain `pending-upsert` until server confirms

### Case 2: remote edit vs older local

Local:

- note = "draft"
- updatedAt = `2026-04-02T09:30:00Z`

Remote:

- note = "final"
- updatedAt = `2026-04-02T10:00:00Z`

Result:

- remote wins
- overwrite local task body
- mark `synced`

### Case 3: local delete vs remote update with same timestamp

Local:

- deletedAt = `2026-04-02T10:00:00Z`
- updatedAt = `2026-04-02T10:00:00Z`

Remote:

- deletedAt = null
- updatedAt = `2026-04-02T10:00:00Z`

Result:

- local tombstone wins because delete wins on equal `updatedAt`

### Case 4: local complete vs remote reopen

Local:

- completed = true
- completedAt = `2026-04-02T10:05:00Z`
- updatedAt = `2026-04-02T10:05:00Z`

Remote:

- completed = false
- completedAt = null
- updatedAt = `2026-04-02T10:03:00Z`

Result:

- local wins because `updatedAt` is later

### Case 5: equal timestamp, both active, different devices

Local:

- updatedAt = `2026-04-02T10:00:00Z`
- updatedByDeviceId = `11111111-1111-4111-8111-111111111111`

Remote:

- updatedAt = `2026-04-02T10:00:00Z`
- updatedByDeviceId = `99999999-9999-4999-8999-999999999999`

Result:

- remote wins because its lowercased `updatedByDeviceId` is lexicographically greater

### Case 6: remote tombstone vs local unsynced active task

Local:

- deletedAt = null
- updatedAt = `2026-04-02T09:50:00Z`
- syncStatus = `pending-upsert`

Remote:

- deletedAt = `2026-04-02T10:00:00Z`
- updatedAt = `2026-04-02T10:00:00Z`

Result:

- remote tombstone wins because `updatedAt` is later
- local task becomes deleted locally

## What Is Intentionally Deferred

These are explicitly not part of version 1:

- field-level merges
- user-visible conflict resolution UI
- semantic merges for `note`, `title`, or checklist-like content
- clock-skew mitigation beyond deterministic LWW
- server-issued vector clocks, revision IDs, or patch logs
- tombstone purge
- merge policies that differ by field or by task state

## Practical Version-1 Rule

When local and remote disagree, choose one full winning task using:

1. later `updatedAt`
2. if tied, deleted wins
3. if tied, lexicographically greater `updatedByDeviceId`
4. if still tied, remote wins

Keep that rule small, deterministic, and identical across both clients.
