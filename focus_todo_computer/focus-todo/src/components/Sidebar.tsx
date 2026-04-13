import { useTranslation } from 'react-i18next'
import { useTodo, useTodoActions } from '../state/useTodo'
import type { Section } from '../types/task'
import styles from './Sidebar.module.css'

const NAV: Section[] = ['today', 'upcoming', 'completed']

export function Sidebar() {
  const {
    state: { ui },
  } = useTodo()
  const { setUi } = useTodoActions()
  const { t } = useTranslation()

  return (
    <aside className={styles.aside} aria-label={t('sidebar.sectionsLabel')}>
      <div className={styles.brand}>
        <span className={styles.mark} aria-hidden />
        <div>
          <div className={styles.title}>{t('brand.title')}</div>
          <div className={styles.sub}>{t('brand.subtitle')}</div>
        </div>
      </div>
      <nav className={styles.nav}>
        {NAV.map((item) => (
          <button
            key={item}
            type="button"
            className={item === ui.section ? styles.active : styles.link}
            onClick={() => setUi({ section: item })}
            title={t(`sections.${item}.navHint`)}
          >
            {t(`sections.${item}.label`)}
          </button>
        ))}
      </nav>
      <p className={styles.footnote}>
        {t('brand.footnote')}
        {/*
        Local only — your tasks stay on this device.
        */}
      </p>
    </aside>
  )
}
