# SolarLink CRM — Deployment Guide

End-to-end setup: from zero accounts to a live URL your beta partners can sign into. Plan for ~45 minutes the first time.

---

## What you're building

A static HTML app (one file) backed by Supabase (Postgres + auth + realtime), deployed on Vercel (or Netlify) at a custom URL. Partners sign in with a magic-link email and get a role-appropriate view.

---

## Prerequisites

You'll need three accounts. None require a credit card to start.

1. **Supabase** — your database + auth → https://supabase.com
2. **Vercel** (or Netlify) — hosting → https://vercel.com (or https://netlify.com)
3. **GitHub** — version control + the Vercel hookup → https://github.com

Optional but recommended for the beta: a custom subdomain (`app.solarlink.io` or similar). DNS pointed at Vercel takes ~10 minutes after deploy.

---

## Step 1 — Create the Supabase project (5 min)

1. Go to https://supabase.com → "New project"
2. Name it `solarlink-crm`
3. Choose a strong database password (save it in your password manager — you'll rarely use it again)
4. Pick a region close to your users
5. Wait ~2 min for the project to spin up

When it's ready, open **Project Settings → API** and copy two values:
- **Project URL** — looks like `https://xxxxx.supabase.co`
- **anon / public key** — a long `eyJ...` JWT

You'll paste these into `config.js` in Step 3.

> Never paste the **service_role** key into anything client-side. The anon key is RLS-protected; service_role bypasses RLS. Treat it like a password.

---

## Step 2 — Run the schema + seed (5 min)

1. In Supabase, click **SQL Editor** in the left nav
2. Click **New query**
3. Open `db/schema.sql` from this repo, copy the entire contents, paste, click **Run**.
4. You should see "Success. No rows returned." (a few times). If you see errors, copy them and fix the underlying issue before continuing — usually a permission problem or an extension that needs enabling.
5. (Optional) Repeat with `db/seed.sql` for demo agencies and leads.

Verify in **Table Editor**: you should see `profiles`, `agencies`, `leads`, `lead_events`, `notifications`, `gift_cards`, and `audit_log`.

---

## Step 3 — Wire up the frontend (2 min)

1. In this project folder, copy `config.example.js` to `config.js`
2. Open `config.js` and paste your Supabase Project URL + anon key
3. Save the file

Test locally by opening `SolarLink-CRM.html` directly in a browser (or `python3 -m http.server` from this folder for cleaner behavior). You should now see the magic-link sign-in screen.

> The `.gitignore` keeps your real `config.js` out of git. Your deployed version will need its own `config.js` — see Step 5.

---

## Step 4 — Configure Supabase Auth (5 min)

In Supabase, go to **Authentication → URL Configuration**:

- **Site URL** — your eventual production URL (e.g. `https://app.solarlink.io` or your Vercel URL `https://solarlink.vercel.app`)
- **Redirect URLs** — add both:
  - `http://localhost:8000` (or wherever you run locally)
  - Your production URL

Without this, the magic-link emails will send users to the wrong place.

Then go to **Authentication → Email Templates → Magic Link** and customize the email if you want it branded. Default works fine for beta.

---

## Step 5 — Create your admin account (3 min)

1. Open the app locally (`python3 -m http.server` from this folder, then http://localhost:8000/SolarLink-CRM.html)
2. Enter your email, click "Send magic link"
3. Check your inbox → click the link → you're signed in (as a default `srp` role)
4. In Supabase Table Editor → `profiles` table → find your row → edit `role` to `admin` → save
5. Refresh the app → you should now see the role-switcher in the sidebar and have full access

This admin account is how you'll promote your first beta partners to their roles.

---

## Step 6 — Push to GitHub (5 min)

```bash
cd "/path/to/Solar Link"
git init
git add .
git status      # confirm config.js is NOT listed (it should be gitignored)
git commit -m "Initial commit — SolarLink CRM"
gh repo create solarlink-crm --private --source=. --push
# OR if you don't have gh CLI: create the repo on github.com first, then:
# git remote add origin https://github.com/YOU/solarlink-crm.git
# git push -u origin main
```

---

## Step 7 — Deploy to Vercel (5 min)

1. Go to https://vercel.com → **New Project**
2. Import your `solarlink-crm` GitHub repo
3. Framework Preset: **Other**
4. Click **Deploy** (no build step needed)
5. When deployment finishes, click the URL — you'll see the sign-in screen, but it will fail to sign in because there's no `config.js` deployed

### Add config.js to the deployment

Vercel ignores `.gitignored` files (correctly). The cleanest path is to use environment variables and a tiny build step, but for v1 we'll keep it simple: commit a `public/config.js` to a private fork, OR use Vercel's file upload feature.

**Simplest approach for the beta:**

1. In Vercel, go to **Project Settings → Environment Variables**
2. Add two variables:
   - `NEXT_PUBLIC_SUPABASE_URL` = your project URL
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = your anon key
3. Create a new file in the project root called `generate-config.sh`:
   ```bash
   #!/bin/bash
   cat > config.js <<EOF
   window.SOLARLINK_CONFIG = {
     supabaseUrl: '$NEXT_PUBLIC_SUPABASE_URL',
     supabaseAnonKey: '$NEXT_PUBLIC_SUPABASE_ANON_KEY'
   };
   EOF
   ```
4. Update `vercel.json` to add a build command:
   ```json
   { "buildCommand": "bash generate-config.sh", ... }
   ```
5. Redeploy

Alternatively, just commit a `config.js` to the **private** repo (the repo is private so the keys aren't public, and the anon key is RLS-protected anyway). For a 5-person beta this is fine. For wider use, the env-var approach above is better.

### Update Supabase auth URLs

Once your Vercel URL is live, go back to Supabase **Authentication → URL Configuration** and add the Vercel URL to both Site URL and Redirect URLs.

---

## Step 8 — Custom subdomain (10 min, optional)

In Vercel → Project → **Domains** → add `app.yourdomain.com`. Vercel gives you a CNAME record. Add it in your DNS provider (Cloudflare, Namecheap, etc.). SSL is automatic.

Update Supabase URL configuration again with your new domain.

---

## Step 9 — Invite your beta partners (5 min)

For each beta partner:
1. Send them the URL
2. They enter their email, click magic link, sign in
3. By default they become an SRP — find them in `profiles` table and update their `role` if they should be a `dsp` / `bdp` / etc.

You can pre-create profiles in advance by emailing yourself first, then editing the row.

---

## Running locally during development

```bash
cd "/path/to/Solar Link"
python3 -m http.server 8000
# Open http://localhost:8000/SolarLink-CRM.html
```

Or just open the file directly — both work, but `localhost` is closer to the production environment.

---

## Troubleshooting

**"Failed to fetch" on sign-in**
Your `config.js` is missing or has wrong values. Check the browser console — Supabase logs the exact URL it tried.

**Magic link goes to the wrong page**
Check Supabase Auth → URL Configuration → Site URL.

**"Permission denied" when reading data**
You're hitting RLS. Either your role is wrong (check `profiles.role` in Supabase) or the policy needs tweaking. The most common issue is a brand-new user trying to see leads that belong to no one — that's correct behavior, by design.

**Realtime updates aren't streaming**
Check Database → Replication in Supabase — confirm `leads`, `notifications`, etc. are toggled on. The schema.sql tries to enable them but it's idempotent and may need a manual toggle on first run.

---

## What's next (post-launch)

Once your beta is humming:

- Add Resend or SendGrid for transactional emails (lead-submitted, stage-changed, etc.)
- Wire `lead_events` into an Activity panel on each lead
- Build the BDP, Agency CEO, and Admin role pages out beyond the current stubs
- Add Sentry for error tracking
- Add PostHog or Plausible for analytics
- Set up Supabase Storage for file uploads (utility bills, install photos)

The schema is designed to support all of this without migrations — every table has a `metadata jsonb` column for future fields, and `lead_events` is already where every state change is logged.
