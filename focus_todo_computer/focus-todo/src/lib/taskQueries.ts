import type {
  CategoryFilter,
  PriorityFilter,
  Section,
  SortOrder,
  StatusFilter,
  Task,
} from '../types/task'
import { localDateISO } from './dates'

export const TASK_SORT_OPTIONS: SortOrder[] = [
  'default',
  'due-date-desc',
  'due-date-asc',
  'priority-desc',
  'priority-asc',
  'title-asc',
  'title-desc',
  'created-desc',
  'created-asc',
]

const PRIORITY_ORDER: Record<Task['priority'], number> = {
  low: 0,
  medium: 1,
  high: 2,
}

function matchesSearch(task: Task, q: string): boolean {
  if (!q.trim()) return true
  const s = q.trim().toLowerCase()
  return (
    task.title.toLowerCase().includes(s) ||
    task.note.toLowerCase().includes(s)
  )
}

function matchesStatus(task: Task, f: StatusFilter): boolean {
  if (f === 'all') return true
  if (f === 'active') return !task.completed
  return task.completed
}

function matchesPriority(task: Task, f: PriorityFilter): boolean {
  if (f === 'all') return true
  return task.priority === f
}

function matchesCategory(task: Task, f: CategoryFilter): boolean {
  if (f === 'all') return true
  return task.category === f
}

export function baseFilters(
  tasks: Task[],
  opts: {
    search: string
    statusFilter: StatusFilter
    priorityFilter: PriorityFilter
    categoryFilter: CategoryFilter
  },
): Task[] {
  return tasks.filter(
    (t) =>
      !t.deletedAt &&
      matchesSearch(t, opts.search) &&
      matchesStatus(t, opts.statusFilter) &&
      matchesPriority(t, opts.priorityFilter) &&
      matchesCategory(t, opts.categoryFilter),
  )
}

function inTodayBucket(task: Task, today: string): boolean {
  if (task.deletedAt) return false
  if (task.completed) return false
  if (!task.dueDate) return true
  return task.dueDate <= today
}

function inUpcomingBucket(task: Task, today: string): boolean {
  if (task.deletedAt) return false
  if (task.completed) return false
  if (!task.dueDate) return false
  return task.dueDate > today
}

export function tasksForSection(
  tasks: Task[],
  section: Section,
  today: string = localDateISO(),
): Task[] {
  switch (section) {
    case 'today':
      return tasks.filter((t) => inTodayBucket(t, today))
    case 'upcoming':
      return tasks.filter((t) => inUpcomingBucket(t, today))
    case 'completed':
      return tasks.filter((t) => t.completed && !t.deletedAt)
    default:
      return tasks.filter((t) => !t.deletedAt)
  }
}

export function visibleTasks(
  tasks: Task[],
  section: Section,
  filters: {
    search: string
    statusFilter: StatusFilter
    priorityFilter: PriorityFilter
    categoryFilter: CategoryFilter
  },
  today: string = localDateISO(),
): Task[] {
  const narrowed = baseFilters(tasks, filters)
  return tasksForSection(narrowed, section, today)
}

function compareStrings(
  a: string,
  b: string,
  direction: 'asc' | 'desc',
): number {
  const left = a.trim().toLowerCase()
  const right = b.trim().toLowerCase()
  const result = left < right ? -1 : left > right ? 1 : 0
  return direction === 'asc' ? result : -result
}

function compareTimestamps(
  a: string,
  b: string,
  direction: 'asc' | 'desc',
): number {
  const at = new Date(a).getTime()
  const bt = new Date(b).getTime()
  const result = at - bt
  return direction === 'asc' ? result : -result
}

function compareDueDates(
  a: Task,
  b: Task,
  direction: 'asc' | 'desc',
  missing: 'start' | 'end',
): number {
  if (!a.dueDate && !b.dueDate) return 0
  if (!a.dueDate) return missing === 'start' ? -1 : 1
  if (!b.dueDate) return missing === 'start' ? 1 : -1
  return direction === 'asc'
    ? a.dueDate.localeCompare(b.dueDate)
    : b.dueDate.localeCompare(a.dueDate)
}

function comparePriority(
  a: Task,
  b: Task,
  direction: 'asc' | 'desc',
): number {
  const result = PRIORITY_ORDER[a.priority] - PRIORITY_ORDER[b.priority]
  return direction === 'asc' ? result : -result
}

function compareDefault(a: Task, b: Task, section: Section): number {
  if (section === 'completed') {
    const completedCompare = compareTimestamps(
      a.completedAt ?? a.updatedAt,
      b.completedAt ?? b.updatedAt,
      'desc',
    )
    if (completedCompare !== 0) return completedCompare
  }

  const dueCompare = compareDueDates(a, b, 'asc', 'start')
  if (dueCompare !== 0) return dueCompare

  const priorityCompare = comparePriority(a, b, 'desc')
  if (priorityCompare !== 0) return priorityCompare

  return compareTimestamps(a.createdAt, b.createdAt, 'desc')
}

function compareStableFallback(a: Task, b: Task): number {
  const createdCompare = compareTimestamps(a.createdAt, b.createdAt, 'desc')
  if (createdCompare !== 0) return createdCompare

  const titleCompare = compareStrings(a.title, b.title, 'asc')
  if (titleCompare !== 0) return titleCompare

  return a.id.localeCompare(b.id)
}

function compareBySortOrder(
  a: Task,
  b: Task,
  section: Section,
  sortOrder: SortOrder,
): number {
  switch (sortOrder) {
    case 'default':
      return compareDefault(a, b, section)
    case 'due-date-desc':
      return (
        compareDueDates(a, b, 'desc', 'end') ||
        comparePriority(a, b, 'desc') ||
        compareStableFallback(a, b)
      )
    case 'due-date-asc':
      return (
        compareDueDates(a, b, 'asc', 'end') ||
        comparePriority(a, b, 'desc') ||
        compareStableFallback(a, b)
      )
    case 'priority-desc':
      return (
        comparePriority(a, b, 'desc') ||
        compareDueDates(a, b, 'asc', 'end') ||
        compareStableFallback(a, b)
      )
    case 'priority-asc':
      return (
        comparePriority(a, b, 'asc') ||
        compareDueDates(a, b, 'asc', 'end') ||
        compareStableFallback(a, b)
      )
    case 'title-asc':
      return (
        compareStrings(a.title, b.title, 'asc') ||
        compareStableFallback(a, b)
      )
    case 'title-desc':
      return (
        compareStrings(a.title, b.title, 'desc') ||
        compareStableFallback(a, b)
      )
    case 'created-desc':
      return (
        compareTimestamps(a.createdAt, b.createdAt, 'desc') ||
        compareStrings(a.title, b.title, 'asc') ||
        a.id.localeCompare(b.id)
      )
    case 'created-asc':
      return (
        compareTimestamps(a.createdAt, b.createdAt, 'asc') ||
        compareStrings(a.title, b.title, 'asc') ||
        a.id.localeCompare(b.id)
      )
    default:
      return compareStableFallback(a, b)
  }
}

export function sortTasksForDisplay(
  tasks: Task[],
  section: Section,
  sortOrder: SortOrder,
): Task[] {
  return [...tasks].sort((a, b) => compareBySortOrder(a, b, section, sortOrder))
}
