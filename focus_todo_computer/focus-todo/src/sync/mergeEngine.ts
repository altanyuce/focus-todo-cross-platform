import type { Task } from '../types/task'

function compareUpdatedAt(left: Task, right: Task): number {
  return Date.parse(left.updatedAt) - Date.parse(right.updatedAt)
}

function compareDeletedPreference(left: Task, right: Task): number {
  const leftDeleted = left.deletedAt !== null
  const rightDeleted = right.deletedAt !== null

  if (leftDeleted === rightDeleted) return 0
  return leftDeleted ? 1 : -1
}

function compareDeviceId(left: Task, right: Task): number {
  return left.updatedByDeviceId
    .toLowerCase()
    .localeCompare(right.updatedByDeviceId.toLowerCase())
}

export function mergeTask(localTask: Task, remoteTask: Task): Task {
  const updatedAtCompare = compareUpdatedAt(localTask, remoteTask)
  if (updatedAtCompare > 0) return { ...localTask }
  if (updatedAtCompare < 0) return { ...remoteTask }

  const deletedCompare = compareDeletedPreference(localTask, remoteTask)
  if (deletedCompare > 0) return { ...localTask }
  if (deletedCompare < 0) return { ...remoteTask }

  const deviceIdCompare = compareDeviceId(localTask, remoteTask)
  if (deviceIdCompare > 0) return { ...localTask }
  if (deviceIdCompare < 0) return { ...remoteTask }

  return { ...remoteTask }
}
