/**
 * SolarLink CRM — runtime config
 *
 * 1. Copy this file to `config.js` (in the same folder)
 * 2. Paste your Supabase project URL + ANON key below
 * 3. Reload the app — you should see the sign-in screen
 *
 * Where to find these values:
 *   Supabase Dashboard → Project Settings → API
 *
 * NOTE: The anon key is safe to expose in the browser. It's protected by
 * Row-Level Security policies defined in db/schema.sql.
 * NEVER paste your service_role key here.
 *
 * Without a config.js file the app falls back to local demo mode
 * (browser localStorage) so the file you committed is safe.
 */
window.SOLARLINK_CONFIG = {
  supabaseUrl:     'https://YOUR-PROJECT.supabase.co',
  supabaseAnonKey: 'YOUR-ANON-KEY-HERE'
};
