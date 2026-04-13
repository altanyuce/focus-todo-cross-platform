import { useEffect, useId, useLayoutEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { SUPPORTED_LANGUAGES, type AppLanguage } from '../i18n'
import { useTodo, useTodoActions, useTodoRealSync } from '../state/useTodo'
import styles from './TopBar.module.css'

type Theme = 'light' | 'dark' | 'system'

function getSystemDark(): boolean {
  return window.matchMedia?.('(prefers-color-scheme: dark)').matches ?? false
}

function applyTheme(theme: Theme) {
  const root = document.documentElement
  if (theme === 'system') {
    root.removeAttribute('data-theme')
    return
  }
  root.setAttribute('data-theme', theme)
}

const THEME_KEY = 'focus-todo-theme'

export function TopBar() {
  const searchId = useId()
  const languageId = useId()
  const {
    state: { ui },
  } = useTodo()
  const { setUi } = useTodoActions()
  const { runOnce } = useTodoRealSync()
  const { t, i18n } = useTranslation()
  const [theme, setThemeState] = useState<Theme>(() => {
    try {
      const saved = localStorage.getItem(THEME_KEY) as Theme | null
      if (saved === 'light' || saved === 'dark' || saved === 'system') {
        return saved
      }
    } catch {
      /* ignore */
    }
    return 'system'
  })
  const [syncState, setSyncState] = useState<
    'idle' | 'syncing' | 'success' | 'error'
  >('idle')
  const [syncMessage, setSyncMessage] = useState<string | null>(null)

  useLayoutEffect(() => {
    applyTheme(theme)
    try {
      localStorage.setItem(THEME_KEY, theme)
    } catch {
      /* ignore */
    }
  }, [theme])

  useEffect(() => {
    if (theme !== 'system') return
    const mq = window.matchMedia('(prefers-color-scheme: dark)')
    const handler = () => applyTheme('system')
    mq.addEventListener('change', handler)
    return () => mq.removeEventListener('change', handler)
  }, [theme])

  const language = SUPPORTED_LANGUAGES.includes(
    i18n.resolvedLanguage as AppLanguage,
  )
    ? (i18n.resolvedLanguage as AppLanguage)
    : 'en'

  async function handleSync() {
    if (syncState === 'syncing') return

    setSyncState('syncing')
    setSyncMessage(null)

    const result = await runOnce()
    if (result.summary.success) {
      setSyncState('success')
      setSyncMessage(t('topBar.syncSuccess'))
      return
    }

    setSyncState('error')
    setSyncMessage(result.summary.errorMessage ?? t('topBar.syncError'))
  }

  return (
    <header className={styles.header}>
      <div className={styles.lead}>
        <h1 className={styles.heading}>{t(`sections.${ui.section}.label`)}</h1>
        <p className={styles.caption}>{t(`sections.${ui.section}.caption`)}</p>
        {/*
          {ui.section === 'today' &&
            'What needs attention now — undated tasks stay here too.'}
          {ui.section === 'upcoming' &&
            'Scheduled work with a future due date.'}
          {ui.section === 'completed' && 'Quiet archive of finished work.'}
        */}
      </div>
      <div className={styles.tools}>
        <label className={styles.searchWrap} htmlFor={searchId}>
          <span className={styles.visuallyHidden}>
            {t('topBar.searchLabel')}
          </span>
          <input
            id={searchId}
            className={styles.search}
            type="search"
            placeholder={t('topBar.searchPlaceholder')}
            value={ui.search}
            onChange={(e) => setUi({ search: e.target.value })}
            autoComplete="off"
          />
        </label>
        <label className={styles.langWrap} htmlFor={languageId}>
          <span className={styles.visuallyHidden}>{t('language.label')}</span>
          <select
            id={languageId}
            className={styles.langSelect}
            value={language}
            onChange={(e) => void i18n.changeLanguage(e.target.value)}
          >
            {SUPPORTED_LANGUAGES.map((code) => (
              <option key={code} value={code}>
                {t(`language.options.${code}`)}
              </option>
            ))}
          </select>
        </label>
        <div className={styles.syncWrap}>
          <button
            type="button"
            className={styles.syncButton}
            onClick={() => void handleSync()}
            disabled={syncState === 'syncing'}
          >
            {syncState === 'syncing'
              ? t('topBar.syncing')
              : t('topBar.syncAction')}
          </button>
          {syncMessage ? (
            <p
              className={
                syncState === 'error' ? styles.syncError : styles.syncStatus
              }
              role="status"
              aria-live="polite"
            >
              {syncMessage}
            </p>
          ) : null}
        </div>
        <div
          className={styles.theme}
          role="group"
          aria-label={t('topBar.themeGroupLabel')}
        >
          <button
            type="button"
            className={theme === 'light' ? styles.themeOn : styles.themeBtn}
            onClick={() => setThemeState('light')}
          >
            {t('theme.light')}
          </button>
          <button
            type="button"
            className={theme === 'dark' ? styles.themeOn : styles.themeBtn}
            onClick={() => setThemeState('dark')}
          >
            {t('theme.dark')}
          </button>
          <button
            type="button"
            className={theme === 'system' ? styles.themeOn : styles.themeBtn}
            onClick={() => setThemeState('system')}
            title={
              getSystemDark()
                ? t('theme.systemDark')
                : t('theme.systemLight')
            }
          >
            {t('theme.system')}
          </button>
        </div>
        {/*
        <label className={styles.searchWrap} htmlFor={searchId}>
          <span className={styles.visuallyHidden}>
            {t('topBar.searchLabel')}
          </span>
          <input
            id={searchId}
            className={styles.search}
            type="search"
            placeholder="Search…"
            value={ui.search}
            onChange={(e) => setUi({ search: e.target.value })}
            autoComplete="off"
          />
        </label>
        <div className={styles.theme} role="group" aria-label="Theme">
          <button
            type="button"
            className={theme === 'light' ? styles.themeOn : styles.themeBtn}
            onClick={() => setThemeState('light')}
          >
            Light
          </button>
          <button
            type="button"
            className={theme === 'dark' ? styles.themeOn : styles.themeBtn}
            onClick={() => setThemeState('dark')}
          >
            Dark
          </button>
          <button
            type="button"
            className={theme === 'system' ? styles.themeOn : styles.themeBtn}
            onClick={() => setThemeState('system')}
            title={
              getSystemDark()
                ? 'System (using dark)'
                : 'System (using light)'
            }
          >
            Auto
          </button>
        </div>
        */}
      </div>
    </header>
  )
}
