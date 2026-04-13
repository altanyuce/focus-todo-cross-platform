import { useEffect, useId, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { formatDisplayDate } from '../lib/dates'
import { useTodoActions } from '../state/useTodo'
import type { Category, Priority, Section, Task } from '../types/task'
import styles from './TaskRow.module.css'

const PRIORITIES: Priority[] = ['low', 'medium', 'high']
const CATEGORIES: Category[] = ['personal', 'work', 'study']

export function TaskRow({
  task,
  section,
}: {
  task: Task
  section: Section
}) {
  const { updateTask, deleteTask, toggleComplete } = useTodoActions()
  const { t, i18n } = useTranslation()
  const [editing, setEditing] = useState(false)
  const [confirmDelete, setConfirmDelete] = useState(false)
  const [draft, setDraft] = useState(task)
  const formId = useId()

  useEffect(() => {
    if (!editing) setDraft(task)
  }, [task, editing])

  const completed = task.completed
  const quiet = section === 'completed'

  function priorityLabel(priority: Priority): string {
    return t(`common.priorities.${priority}`)
  }

  function categoryLabel(category: Category): string {
    return t(`common.categories.${category}`)
  }

  function save() {
    updateTask(task.id, {
      title: draft.title.trim() || task.title,
      note: draft.note,
      dueDate: draft.dueDate,
      priority: draft.priority,
      category: draft.category,
    })
    setEditing(false)
    setConfirmDelete(false)
  }

  function cancel() {
    setDraft(task)
    setEditing(false)
    setConfirmDelete(false)
  }

  return (
    <article
      className={`${styles.card} ${quiet ? styles.quiet : ''} ${completed ? styles.done : ''}`}
    >
      <div className={styles.row}>
        <label className={styles.checkWrap}>
          <input
            type="checkbox"
            className={styles.check}
            checked={completed}
            onChange={() => toggleComplete(task.id)}
            aria-label={completed ? t('task.markActive') : t('task.markComplete')}
          />
          <span className={styles.checkVisual} aria-hidden />
        </label>
        <div className={styles.main}>
          {editing ? (
            <div className={styles.edit} id={formId}>
              <label className={styles.visuallyHidden} htmlFor={`${formId}-title`}>
                {t('task.titleLabel')}
              </label>
              <input
                id={`${formId}-title`}
                className={styles.titleInput}
                value={draft.title}
                onChange={(e) =>
                  setDraft((d) => ({ ...d, title: e.target.value }))
                }
              />
              <label className={styles.smallLabel} htmlFor={`${formId}-note`}>
                {t('task.noteLabel')}
              </label>
              <textarea
                id={`${formId}-note`}
                className={styles.noteInput}
                rows={2}
                value={draft.note}
                onChange={(e) =>
                  setDraft((d) => ({ ...d, note: e.target.value }))
                }
              />
              <div className={styles.editGrid}>
                <label className={styles.inlineField}>
                  <span className={styles.inlineLab}>{t('task.due')}</span>
                  <input
                    type="date"
                    className={styles.inlineControl}
                    value={draft.dueDate ?? ''}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        dueDate: e.target.value || null,
                      }))
                    }
                  />
                </label>
                <label className={styles.inlineField}>
                  <span className={styles.inlineLab}>{t('task.priority')}</span>
                  <select
                    className={styles.inlineControl}
                    value={draft.priority}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        priority: e.target.value as Priority,
                      }))
                    }
                  >
                    {PRIORITIES.map((p) => (
                      <option key={p} value={p}>
                        {priorityLabel(p)}
                      </option>
                    ))}
                  </select>
                </label>
                <label className={styles.inlineField}>
                  <span className={styles.inlineLab}>{t('task.list')}</span>
                  <select
                    className={styles.inlineControl}
                    value={draft.category}
                    onChange={(e) =>
                      setDraft((d) => ({
                        ...d,
                        category: e.target.value as Category,
                      }))
                    }
                  >
                    {CATEGORIES.map((c) => (
                      <option key={c} value={c}>
                        {categoryLabel(c)}
                      </option>
                    ))}
                  </select>
                </label>
              </div>
              <div className={styles.editActions}>
                <button type="button" className={styles.primaryBtn} onClick={save}>
                  {t('task.save')}
                </button>
                <button type="button" className={styles.ghostBtn} onClick={cancel}>
                  {t('task.cancel')}
                </button>
              </div>
            </div>
          ) : (
            <>
              <div className={styles.titleRow}>
                <span className={styles.title}>{task.title}</span>
                <span
                  className={styles.prio}
                  data-priority={task.priority}
                  aria-label={t('task.priorityAria', {
                    priority: priorityLabel(task.priority),
                  })}
                />
              </div>
              {task.note ? (
                <p className={styles.note}>{task.note}</p>
              ) : null}
              <div className={styles.meta}>
                <span className={styles.cat}>{categoryLabel(task.category)}</span>
                {task.dueDate ? (
                  <span className={styles.due}>
                    {formatDisplayDate(task.dueDate, i18n.resolvedLanguage || 'en')}
                  </span>
                ) : (
                  <span className={styles.noDue}>{t('task.noDate')}</span>
                )}
              </div>
            </>
          )}
        </div>
        {!editing && (
          <div className={styles.actions}>
            {confirmDelete ? (
              <div
                className={styles.confirmBar}
                role="group"
                aria-label={t('task.confirmDeleteGroup')}
              >
                <span className={styles.confirmText}>{t('task.confirmDeleteText')}</span>
                <button
                  type="button"
                  className={styles.dangerBtn}
                  onClick={() => deleteTask(task.id)}
                >
                  {t('task.confirmYes')}
                </button>
                <button
                  type="button"
                  className={styles.actionBtn}
                  onClick={() => setConfirmDelete(false)}
                >
                  {t('task.confirmNo')}
                </button>
              </div>
            ) : (
              <>
                <button
                  type="button"
                  className={styles.actionBtn}
                  onClick={() => {
                    setConfirmDelete(false)
                    setEditing(true)
                  }}
                >
                  {t('task.edit')}
                </button>
                <button
                  type="button"
                  className={styles.actionBtn}
                  onClick={() => setConfirmDelete(true)}
                >
                  {t('task.delete')}
                </button>
              </>
            )}
          </div>
        )}
      </div>
    </article>
  )
}
