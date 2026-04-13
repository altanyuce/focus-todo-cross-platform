import type { Task, TaskSyncMetadata } from '../types/task'

export function getOutboundTasks(
  tasks: Task[],
  syncMetadata: TaskSyncMetadata[],
): Task[] {
  const pendingTaskIds = new Set(
    syncMetadata
      .filter(
        (item) =>
          item.syncStatus === 'pending-upsert' ||
          item.syncStatus === 'pending-delete',
      )
      .map((item) => item.taskId),
  )

  return tasks.filter((task) => pendingTaskIds.has(task.id))
}
