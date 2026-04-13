TASK CONTRACT

Version: 1.1

Status: Canonical pre-sync contract



\----------------------------------------



1\. PURPOSE



This document defines the canonical task rules shared by Desktop and Mobile apps.



If there is a conflict between code and this document, this document is correct.



\----------------------------------------



2\. CORE RULES



\- Sync payload = ONLY task data

\- UI state = NEVER synced

\- Delete = ALWAYS soft delete (deletedAt)

\- Conflict = Last Write Wins (updatedAt)

\- Client MUST NOT invent timestamps

\- Invalid data = repair if safe, otherwise drop



\----------------------------------------



3\. TASK STRUCTURE



Each task must follow this structure:



schemaVersion: number

id: string (UUID)

title: string

completed: boolean

createdAt: ISO timestamp

updatedAt: ISO timestamp

createdByDeviceId: string

updatedByDeviceId: string



Optional fields:

note: string

dueDate: YYYY-MM-DD or null

priority: string or null

category: string or null

completedAt: ISO timestamp or null

deletedAt: ISO timestamp or null



\----------------------------------------



4\. REQUIRED VALID TASK



A task is valid ONLY IF:



\- id exists and is UUID

\- title is not empty

\- completed is boolean

\- createdAt is valid

\- updatedAt is valid

\- createdByDeviceId exists

\- updatedByDeviceId exists



If these fail → DROP TASK



\----------------------------------------



5\. FIELD RULES



TITLE:

\- must not be empty



NOTE:

\- always string

\- invalid → ""



DUEDATE:

\- format YYYY-MM-DD

\- invalid → null



PRIORITY:

\- string or null

\- unknown values allowed



CATEGORY:

\- string or null

\- unknown values allowed



COMPLETED:

\- boolean

\- invalid → false



COMPLETEDAT:

\- if completed = false → null

\- if completed = true → must be valid

\- invalid → set completed = false



DELETEDAT:

\- null = active

\- timestamp = deleted

\- invalid → null



CREATEDAT:

\- must be valid

\- invalid → DROP TASK



UPDATEDAT:

\- must be valid

\- invalid → set = createdAt



\----------------------------------------



6\. MUTATION RULES



ON CREATE:

\- id = new UUID

\- createdAt = now

\- updatedAt = now

\- completed = false

\- completedAt = null

\- deletedAt = null



ON UPDATE:

\- updatedAt = now



ON COMPLETE:

\- completed = true

\- completedAt = now

\- updatedAt = now



ON REOPEN:

\- completed = false

\- completedAt = null

\- updatedAt = now



ON DELETE:

\- deletedAt = now

\- updatedAt = now

\- NEVER hard delete



\----------------------------------------



7\. DEVICE ID



\- generated once

\- stored locally

\- must be UUID

\- never changes



\----------------------------------------



8\. SYNC METADATA (LOCAL ONLY)



taskId: string

syncStatus: pending-upsert | pending-delete | synced | error

lastSyncedAt: timestamp or null

lastSyncError: string or null



NOT part of sync payload



\----------------------------------------



9\. CONFLICT RESOLUTION



Rule: Last Write Wins



Order:

1\. higher updatedAt wins

2\. if equal → deleted wins

3\. if equal → compare deviceId



\----------------------------------------



10\. STORAGE RULES



Separate storage:



\- tasks

\- sync metadata

\- UI state

\- device ID



NEVER combine them



\----------------------------------------



11\. VISIBILITY RULES



SHOW ONLY if:

\- deletedAt = null



TODAY:

\- not completed

\- dueDate <= today OR null



UPCOMING:

\- not completed

\- dueDate > today



COMPLETED:

\- completed = true



\----------------------------------------



12\. SEARCH



\- case insensitive

\- search in title + note



\----------------------------------------



13\. SORT



Must match across platforms:



\- title asc/desc

\- created asc/desc

\- dueDate asc/desc

\- priority asc/desc



\----------------------------------------



14\. NON-GOALS



NOT included:



\- auth

\- backend

\- multi-user

\- realtime sync

\- subtasks

\- attachments



\----------------------------------------



15\. SUMMARY



\- Task is the ONLY sync payload

\- Delete is soft delete

\- Conflict = updatedAt

\- No fake data

\- Drop invalid tasks if needed

\- Desktop and Mobile MUST behave the same

