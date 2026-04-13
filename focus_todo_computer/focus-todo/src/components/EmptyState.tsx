import { useTranslation } from 'react-i18next'
import type { Section } from '../types/task'
import styles from './EmptyState.module.css'

export function EmptyState({ section }: { section: Section }) {
  const { t } = useTranslation()

  return (
    <div className={styles.wrap} data-testid="empty-state">
      <p className={styles.title}>{t(`sections.${section}.emptyTitle`)}</p>
      <p className={styles.body}>{t(`sections.${section}.emptyBody`)}</p>
    </div>
  )
}
