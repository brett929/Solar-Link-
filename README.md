# SolarLink CRM

A solar referral CRM built as a single-file HTML app, backed by Supabase (Postgres + auth + realtime), deployed as a static site.

## Stack

- **Frontend**: One HTML file — vanilla JS, CSS, no build step
- **Backend**: Supabase (Postgres, Row-Level Security, Auth, Realtime)
- **Hosting**: Vercel or Netlify (static)
- **Email**: Magic-link via Supabase Auth (Resend/SendGrid wiring coming post-beta)

## Roles

Every signed-in user has exactly one role:

- **`srp`** — Strategic Referral Partner (Realtor, MLO, insurance agent, etc.)
- **`dspit`** — DSP In Training
- **`dsp`** — Direct Sales Pro (closes deals)
- **`bdp`** — Business Development (recruits agencies)
- **`agency`** — Agency CEO
- **`admin`** — Full access

The role is stored in `profiles.role` and enforced by RLS policies. The frontend reads it on sign-in and adjusts navigation/permissions accordingly.

## Getting started

See [DEPLOYMENT.md](./DEPLOYMENT.md) for the end-to-end setup: create a Supabase project, run the schema, deploy to Vercel, invite your first users. ~45 minutes the first time.

For just running locally:

```bash
cp config.example.js config.js
# Edit config.js with your Supabase URL + anon key
python3 -m http.server 8000
open http://localhost:8000/SolarLink-CRM.html
```

Without `config.js` the app falls back to a localStorage-backed demo mode — no Supabase needed, no sign-in screen.

## Project structure

```
.
├── SolarLink-CRM.html       The entire frontend (HTML + CSS + JS in one file)
├── config.example.js        Template for your Supabase keys (copy → config.js)
├── config.js                Your actual keys (gitignored — create from template)
├── vercel.json              Vercel deploy config (SPA routing + security headers)
├── netlify.toml             Netlify alternative
├── DEPLOYMENT.md            Step-by-step launch guide
├── README.md                You are here
└── db/
    ├── schema.sql           Tables, RLS, triggers, realtime — run first
    ├── seed.sql             Demo agencies + leads — run second (optional)
    └── README.md            Schema notes
```

## Architecture decisions

**Single file frontend.** No build step, no node_modules, no bundler. The whole app ships as one HTML file that loads Supabase + Inter from CDNs. Trade-off: fewer files to manage and zero deploy complexity vs. less code organization. For a CRM at this stage, simplicity wins.

**Supabase for everything backend.** Postgres for data, RLS for multi-tenant security, Auth for magic-link sign-in, Realtime for live notification streaming. Replaces what would otherwise be three services with one.

**RLS over backend filtering.** All access control happens in Postgres policies, not in application code. The frontend just queries `from('leads').select()` — Postgres decides what the user can see. This is harder to get right initially but vastly more secure than a wrapper-style backend.

**Optimistic UI with write-through.** New leads appear instantly in the UI and write to Supabase in the background. On error, a toast surfaces it. Cleaner UX than blocking the UI on every roundtrip.

**Roles in the database, not the URL.** The role-switcher in the sidebar is admin-only. Everyone else gets exactly one role assigned in `profiles.role`. This matches how real CRMs work and keeps RLS simple.

## What's working today

- Full UI: dashboards, KPIs, lead submission, pipeline, network views — all 7 roles
- Cmd+K command palette across every view, lead, and agency
- Toast notifications, modal management, ESC key handling
- Mobile responsive (sidebar collapses below 880px)
- Accessibility basics: ARIA roles, keyboard nav, skip-link, focus rings
- CSV export on the leads table
- Print styles
- Magic-link auth with Supabase
- Cloud-backed persistence with realtime streaming
- localStorage fallback when Supabase isn't configured

## What's next

See the post-launch roadmap at the bottom of `DEPLOYMENT.md`.

## License

Proprietary. Not for redistribution.
