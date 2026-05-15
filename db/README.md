# SolarLink CRM — Database

Two SQL files. Run them in order in the Supabase SQL Editor.

## 1. `schema.sql`

The full Postgres schema:
- **Tables**: `profiles`, `agencies`, `leads`, `lead_events`, `notifications`, `gift_cards`, `audit_log`
- **Triggers**: auto-create profile on signup, auto-log stage changes, auto-update `updated_at`
- **Functions**: `current_user_role()`, `is_admin()` (used in RLS)
- **RLS policies**: multi-tenant access — SRPs see their own leads, DSPs see assigned leads, agency CEOs see their roster's leads, admins see everything
- **Realtime publication**: `leads`, `lead_events`, `notifications`, `gift_cards` are streamed to subscribed clients

Idempotent — safe to re-run.

## 2. `seed.sql`

Demo data for the beta:
- 5 agencies (Sunridge Realty, Apex Insurance, etc.)
- 12 leads (mix of stages, mix of sources)
- 5 gift cards tied to those leads

No profiles are seeded — those are created automatically when users sign in via magic link.

After signup, manually promote your admin user in the Table Editor:
1. `profiles` table → find your row → set `role` to `admin` → save

## Schema notes

- `leads.public_id` is auto-generated as `L-xxxxxx` from the row UUID. The UI uses this as the human-friendly ID.
- All tables have a `metadata jsonb` column for future fields that don't deserve a migration.
- `lead_events` is the activity log for every stage change, comment, file attachment, or payout event — designed to power a future Activity panel on the lead detail view.
- `audit_log` is admin-only and captures destructive or sensitive actions (assignments, role changes, deletions).

## Re-running schema.sql

The schema is idempotent (uses `if not exists`, `drop ... if exists`, `on conflict do nothing`). It's safe to re-run any time. If you change a policy or trigger, just re-run the whole file.

## Re-running seed.sql

Also safe. Uses fixed UUIDs and `on conflict (id) do nothing`. If you want a clean slate:

```sql
truncate table notifications, lead_events, gift_cards, leads, audit_log, agencies cascade;
-- then re-run seed.sql
```

(Don't truncate `profiles` — that nukes the link to your auth users.)
