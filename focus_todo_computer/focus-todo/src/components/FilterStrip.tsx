import { useId } from 'react'
import { useTranslation } from 'react-i18next'
import { TASK_SORT_OPTIONS } from '../lib/taskQueries'
import { useTodo, useTodoActions } from '../state/useTodo'
import type {
  CategoryFilter,
  PriorityFilter,
  SortOrder,
  StatusFilter,
} from '../types/task'
import styles from './FilterStrip.module.css'

export function FilterStrip() {
  const {
    state: { ui },
  } = useTodo()
  const { setUi } = useTodoActions()
  const { t } = useTranslation()
  const base = useId()

  return (
    <div className={styles.strip} role="group" aria-label={t('filters.groupLabel')}>
      <span className={styles.muted}>{t('filters.heading')}</span>
      <label className={styles.item} htmlFor={`${base}-status`}>
        <span className={styles.lab}>{t('filters.status')}</span>
        <select
          id={`${base}-status`}
          className={styles.select}
          value={ui.statusFilter}
          onChange={(e) =>
            setUi({ statusFilter: e.target.value as StatusFilter })
          }
        >
          <option value="all">{t('filters.statusOptions.all')}</option>
          <option value="active">{t('filters.statusOptions.active')}</option>
          <option value="done">{t('filters.statusOptions.done')}</option>
        </select>
      </label>
      <label className={styles.item} htmlFor={`${base}-priority`}>
        <span className={styles.lab}>{t('filters.priority')}</span>
        <select
          id={`${base}-priority`}
          className={styles.select}
          value={ui.priorityFilter}
          onChange={(e) =>
            setUi({ priorityFilter: e.target.value as PriorityFilter })
          }
        >
          <option value="all">{t('filters.priorityOptions.all')}</option>
          <option value="low">{t('common.priorities.low')}</option>
          <option value="medium">{t('common.priorities.medium')}</option>
          <option value="high">{t('common.priorities.high')}</option>
        </select>
      </label>
      <label className={styles.item} htmlFor={`${base}-category`}>
        <span className={styles.lab}>{t('filters.list')}</span>
        <select
          id={`${base}-category`}
          className={styles.select}
          value={ui.categoryFilter}
          onChange={(e) =>
            setUi({ categoryFilter: e.target.value as CategoryFilter })
          }
        >
          <option value="all">{t('filters.categoryOptions.all')}</option>
          <option value="personal">{t('common.categories.personal')}</option>
          <option value="work">{t('common.categories.work')}</option>
          <option value="study">{t('common.categories.study')}</option>
        </select>
      </label>
      <label className={styles.item} htmlFor={`${base}-sort`}>
        <span className={styles.lab}>{t('filters.sort')}</span>
        <select
          id={`${base}-sort`}
          className={`${styles.select} ${styles.sortSelect}`}
          value={ui.sortOrder}
          onChange={(e) => setUi({ sortOrder: e.target.value as SortOrder })}
        >
          {TASK_SORT_OPTIONS.map((option) => (
            <option key={option} value={option}>
              {t(`filters.sortOptions.${option}`)}
            </option>
          ))}
        </select>
      </label>
      {(ui.statusFilter !== 'all' ||
        ui.priorityFilter !== 'all' ||
        ui.categoryFilter !== 'all' ||
        ui.sortOrder !== 'default') && (
        <button
          type="button"
          className={styles.clear}
          onClick={() =>
            setUi({
              statusFilter: 'all',
              priorityFilter: 'all',
              categoryFilter: 'all',
              sortOrder: 'default',
            })
          }
        >
          {t('filters.clear')}
        </button>
      )}
    </div>
  )
}
