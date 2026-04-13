/** Local calendar date as YYYY-MM-DD */
export function localDateISO(d: Date = new Date()): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

export function parseLocalDate(iso: string): Date {
  const [y, mo, d] = iso.split('-').map(Number)
  return new Date(y, mo - 1, d)
}

export function formatDisplayDate(iso: string, locale: string): string {
  const d = parseLocalDate(iso)
  return d.toLocaleDateString(locale, {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
  })
}
