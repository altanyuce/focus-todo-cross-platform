import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'
import de from './locales/de.json'
import en from './locales/en.json'
import es from './locales/es.json'
import it from './locales/it.json'
import tr from './locales/tr.json'

export const SUPPORTED_LANGUAGES = ['en', 'tr', 'de', 'es', 'it'] as const

export type AppLanguage = (typeof SUPPORTED_LANGUAGES)[number]

const LANGUAGE_STORAGE_KEY = 'focus-todo-language'

const resources = {
  en: { translation: en },
  tr: { translation: tr },
  de: { translation: de },
  es: { translation: es },
  it: { translation: it },
} as const

function isSupportedLanguage(value: string): value is AppLanguage {
  return SUPPORTED_LANGUAGES.includes(value as AppLanguage)
}

function normalizeLanguage(value: string | null | undefined): AppLanguage | null {
  if (!value) return null
  const [base] = value.toLowerCase().split('-')
  return isSupportedLanguage(base) ? base : null
}

function getInitialLanguage(): AppLanguage {
  try {
    const stored = normalizeLanguage(localStorage.getItem(LANGUAGE_STORAGE_KEY))
    if (stored) return stored
  } catch {
    /* ignore */
  }

  if (typeof navigator !== 'undefined') {
    const browserLanguage = normalizeLanguage(navigator.language)
    if (browserLanguage) return browserLanguage
  }

  return 'en'
}

void i18n.use(initReactI18next).init({
  resources,
  lng: getInitialLanguage(),
  fallbackLng: 'en',
  interpolation: {
    escapeValue: false,
  },
})

i18n.on('languageChanged', (language) => {
  const normalized = normalizeLanguage(language) ?? 'en'
  document.documentElement.lang = normalized

  try {
    localStorage.setItem(LANGUAGE_STORAGE_KEY, normalized)
  } catch {
    /* ignore */
  }
})

export default i18n
