# Supabase Sync Setup

## Purpose

This project now includes a Supabase transport layer that is safe to ship without credentials.

If Supabase is not configured:

- the app does not crash
- the transport reports a controlled "not configured" error
- the existing sync pipeline can convert that into local sync metadata error state

## What You Need From Supabase

You need two values from your Supabase project:

- Project URL
- anon public API key

In the Supabase dashboard, these are typically available under:

- `Project Settings`
- `API`

Look for:

- `Project URL`
- `Project API keys`
  - use the `anon` / public key

## Desktop Setup

Desktop reads from Vite environment variables:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

Create a local env file in `focus_todo_computer/focus-todo`:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Example:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

## Mobile Setup

Mobile reads from Dart compile-time defines:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Example run command:

```powershell
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Example:

```powershell
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

## Current Transport Behavior

Without config:

- `pushTasks(...)` throws a controlled not-configured error
- `pullTasks(...)` throws a controlled not-configured error
- the sync pipeline can catch that and mark affected task sync metadata as `error`

With config:

- the transport uses Supabase REST endpoints
- outbound canonical task payloads are pushed to the `tasks` table
- remote tasks are pulled from the same table using `select=*`

## Integration Notes

- No secrets are hardcoded.
- No auth flow is required for this stage.
- No UI state is synced.
- No realtime or background sync is enabled.
- The transport interface remains backend-agnostic, so this layer can still be swapped later if needed.
