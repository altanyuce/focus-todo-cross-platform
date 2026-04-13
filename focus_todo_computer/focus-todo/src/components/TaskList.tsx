import { useMemo } from 'react'
import { useTodo } from '../state/useTodo'
import { sortTasksForDisplay, visibleTasks } from '../lib/taskQueries'
import type { Section } from '../types/task'
import { EmptyState } from './EmptyState'
import { TaskRow } from './TaskRow'
import styles from './TaskList.module.css'

const SECTIONS: Section[] = ['today', 'upcoming', 'completed']

export function TaskList() {
  const {
    state: { tasks, ui },
  } = useTodo()

  const listsBySection = useMemo(
    () =>
      Object.fromEntries(
        SECTIONS.map((section) => {
          const visible = visibleTasks(tasks, section, {
            search: ui.search,
            statusFilter: ui.statusFilter,
            priorityFilter: ui.priorityFilter,
            categoryFilter: ui.categoryFilter,
          })

          return [
            section,
            sortTasksForDisplay(visible, section, ui.sortOrder),
          ]
        }),
      ) as Record<Section, typeof tasks>,
    [
      tasks,
      ui.search,
      ui.statusFilter,
      ui.priorityFilter,
      ui.categoryFilter,
      ui.sortOrder,
    ],
  )

  return (
    <div className={styles.list}>
      {SECTIONS.map((section) => {
        const list = listsBySection[section]

        return (
          <div
            key={section}
            className={styles.panel}
            hidden={section !== ui.section}
            aria-hidden={section !== ui.section}
          >
            {list.length === 0 ? (
              <EmptyState section={section} />
            ) : (
              <ul className={styles.ul}>
                {list.map((task) => (
                  <li key={task.id}>
                    <TaskRow task={task} section={section} />
                  </li>
                ))}
              </ul>
            )}
          </div>
        )
      })}
    </div>
  )
}
