import { useId, useState, type FormEvent, type KeyboardEvent } from 'react'
import { useTranslation } from 'react-i18next'
import { useTodoActions } from '../state/useTodo'
import type { Category, Priority } from '../types/task'
import styles from './QuickAdd.module.css'

const PRIORITIES: Priority[] = ['low', 'medium', 'high']
const CATEGORIES: Category[] = ['personal', 'work', 'study']

export function QuickAdd() {
  const { addTask } = useTodoActions()
  const { t } = useTranslation()
  const titleId = useId()
  const [title, setTitle] = useState('')
  const [expanded, setExpanded] = useState(false)
  const [note, setNote] = useState('')
  const [dueDate, setDueDate] = useState('')
  const [priority, setPriority] = useState<Priority>('medium')
  const [category, setCategory] = useState<Category>('personal')

  function resetOptional() {
    setNote('')
    setDueDate('')
    setPriority('medium')
    setCategory('personal')
  }

  function submit() {
    const trimmedTitle = title.trim()
    if (!trimmedTitle) return
    addTask({
      title: trimmedTitle,
      note,
      dueDate: dueDate || null,
      priority,
      category,
    })
    setTitle('')
    resetOptional()
    setExpanded(false)
  }

  function onSubmit(e: FormEvent) {
    e.preventDefault()
    submit()
  }

  function onKeyDown(e: KeyboardEvent<HTMLInputElement>) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      submit()
    }
  }

  return (
    <section className={styles.section} aria-label={t('quickAdd.sectionLabel')}>
      <form className={styles.form} onSubmit={onSubmit}>
        <label className={styles.visuallyHidden} htmlFor={titleId}>
          {t('quickAdd.titleLabel')}
        </label>
        <input
          id={titleId}
          className={styles.input}
          type="text"
          placeholder={t('quickAdd.titlePlaceholder')}
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          onKeyDown={onKeyDown}
          autoComplete="off"
        />
        {/*
        <input
          id={titleId}
          className={styles.input}
          type="text"
          placeholder="Add a task — press Enter"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          onKeyDown={onKeyDown}
          autoComplete="off"
        />
        */}
        <button
          type="button"
          className={styles.toggle}
          onClick={() => setExpanded((x) => !x)}
          aria-expanded={expanded}
        >
          {expanded ? t('quickAdd.detailsHide') : t('quickAdd.detailsShow')}
        </button>
      </form>
      {expanded && (
        <div className={styles.details}>
          <label className={styles.field}>
            <span className={styles.label}>{t('quickAdd.note')}</span>
            <textarea
              className={styles.textarea}
              rows={2}
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder={t('quickAdd.notePlaceholder')}
            />
          </label>
          <div className={styles.row}>
            <label className={styles.field}>
              <span className={styles.label}>{t('quickAdd.due')}</span>
              <input
                className={styles.date}
                type="date"
                value={dueDate}
                onChange={(e) => setDueDate(e.target.value)}
              />
            </label>
            <label className={styles.field}>
              <span className={styles.label}>{t('quickAdd.priority')}</span>
              <select
                className={styles.select}
                value={priority}
                onChange={(e) =>
                  setPriority(e.target.value as Priority)
                }
              >
                {PRIORITIES.map((p) => (
                  <option key={p} value={p}>
                    {t(`common.priorities.${p}`)}
                  </option>
                ))}
              </select>
            </label>
            <label className={styles.field}>
              <span className={styles.label}>{t('quickAdd.list')}</span>
              <select
                className={styles.select}
                value={category}
                onChange={(e) =>
                  setCategory(e.target.value as Category)
                }
              >
                {CATEGORIES.map((c) => (
                  <option key={c} value={c}>
                    {t(`common.categories.${c}`)}
                  </option>
                ))}
              </select>
            </label>
          </div>
        </div>
      )}
    </section>
  )
}
