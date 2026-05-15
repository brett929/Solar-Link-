# SolarLink CRM — 2-Week Beta Roadmap

**Target:** closed beta with 5–20 real partners by **2026-05-25** (14 days from 2026-05-11).

**Operating principle:** ruthless scope. Every hour on the BDP role or AI lead scoring is an hour not on the backend.

---

## Status snapshot (2026-05-11)

| Area | State |
|---|---|
| Supabase schema + RLS | ✅ Applied to project `fsgstepnomneydpidjop` |
| Seed data (5 agencies, 12 leads, 5 gift cards) | ✅ Loaded |
| Realtime publication (leads, lead_events, notifications, gift_cards) | ✅ Active |
| Cloud bridge in HTML (`createLead`, `updateLeadStage`, `addLeadEvent`, reads) | ✅ Wired ([SolarLink-CRM.html:4222](SolarLink-CRM.html#L4222)) |
| Magic-link auth (`signInWithOtp` + `onAuthStateChange`) | ✅ Wired |
| Auth Site URL + redirect allow list | ✅ `http://localhost:8000` (prod URL pending) |
| First admin profile | ⏳ Pending first sign-in |
| Hash routing | ❌ Not present |
| Resend / transactional email | ❌ Not present |
| Lead detail modal (`openLead` exists) | ⚠️ Exists; needs audit for full notes + activity log |
| Sentry | ❌ Not present |
| First-time onboarding flow | ❌ Not present |
| Deployed to Vercel/Netlify | ❌ Local only |

---

## Day-by-day

### Days 1–3 — Backend (Supabase)
Design schema; swap every localStorage/SafeStore call for a Supabase client call. Use realtime so the notification drawer updates live across devices. The single biggest unlock — once done, everything else is incremental.

- **Schema designed + applied** — ✅ done 2026-05-11 (tables: `profiles`, `agencies`, `leads`, `lead_events`, `notifications`, `gift_cards`, `audit_log`)
- **Realtime publication enabled** — ✅ done
- **Mutation write-through** — ✅ done for `createLead`, `updateLeadStage`, `addLeadEvent`
- **Audit needed:** confirm *every* mutation path writes through (notifications, gift cards, agency edits, profile edits). Anything still hitting localStorage-only is a silent data-loss bug for beta partners on a second device.

### Days 3–4 — Authentication
Magic-link sign-in. Drop the role dropdown — look up the logged-in user's role from `profiles` on load. Admin can promote users to SRP / DSP / Agency CEO.

- **Magic link flow** — ✅ wired ([SolarLink-CRM.html:4247](SolarLink-CRM.html#L4247))
- **Role lookup from `profiles`** — ✅ wired ([SolarLink-CRM.html:4265](SolarLink-CRM.html#L4265))
- **First admin promotion** — ⏳ blocked on Brett's first sign-in; one SQL update once email lands
- **Admin "promote user" UI** — ❌ to build (or postpone — admin can edit `profiles.role` directly in Supabase Table Editor for beta)

### Day 4 — Deploy
Vercel or Netlify, static deploy, custom subdomain (`app.solarlink.io`). HTTPS automatic. Env vars hold Supabase keys.

- `vercel.json` and `netlify.toml` already present
- Need: push to GitHub, import to Vercel, decide config-injection strategy (env-var build step vs. committing `config.js` to private repo — see [DEPLOYMENT.md:118](DEPLOYMENT.md#L118))
- After deploy: add prod URL to Supabase auth allow list (one PATCH call — I can run it)

### Days 5–6 — Transactional email (Resend)
Send real emails on lead submitted, consult booked, deal closed. Templates exist as text inside Talk Tracks / Scripts tabs — just need wiring. Use Supabase Edge Functions or a tiny serverless endpoint.

- Sign up for Resend, get API key
- Decide: Edge Function vs. Vercel serverless function (Edge Function keeps it inside Supabase)
- 3 email types for v1: `lead.submitted`, `lead.consult_booked`, `lead.closed`
- Trigger via DB webhook on `lead_events` row insert (cleanest — no client-side trigger needed)

### Day 6 — URL routing
Hash-based (`#/srp/srp-3/my-leads` → parse and route). ~50 lines. Every view deep-linkable, survives refresh.

- Read `location.hash` on load + `hashchange` listener
- Update hash when navigating between sections / opening leads
- Migrate "open lead via modal" to "open lead via `#/lead/L-1234`" so refresh-on-deeplink works

### Days 7–8 — Lead workflow (the heart of the CRM)
Click lead → modal → change stage, write notes, see activity log. Every state change writes to `lead_events`. Activity log = audit trail.

- `openLead` modal exists ([SolarLink-CRM.html:2718](SolarLink-CRM.html#L2718)) — **needs audit**: does it currently support note entry + show `lead_events` history?
- `addLeadEvent` infrastructure exists ([SolarLink-CRM.html:4346](SolarLink-CRM.html#L4346)) — wire it to a notes textarea in the modal
- Render `lead_events` reverse-chronological inside the modal
- Every stage change should already write a `lead_events` row via the existing `updateLeadStage` flow — verify

### Day 9 — Bug bash + observability
- Drop Sentry in (10-min integration, free tier covers beta)
- Non-engineer runs every flow as SRP and DSP — fix what breaks
- Add error toasts to *every* Supabase call (currently only `createLead` and `updateLeadStage` toast — profile fetch and others fail silently)

### Day 10 — Onboarding flow
First-time SRP lands on a welcome dashboard with 3 CTAs: "Submit your first lead," "Watch the 2-min product tour," "Open the Brain Jogger." Hides after first lead submitted.

- Conditional render based on `STATE.leads.filter(l => l.srpId === currentUser.id).length === 0`
- No tooltips library needed

### Days 11–14 — Buffer
Beta partners ask for things you didn't anticipate. **Reserve 30% of timeline for that.**

---

## Explicitly cut from beta

- **BDP, Agency CEO, Admin roles** — stay skeletal. Beta users are SRPs + the DSPs who close their leads.
- **SMS via Twilio** — post-beta
- **File uploads** — post-beta (partners can email photos)
- **AI lead scoring** — post-beta
- **Calendar integration, KYC, billing** — post-beta
- **Unique partner referral URLs** — tempting but a week of work for tracking + attribution. Defer.

---

## Open questions / handoff items

1. **First admin promotion** — send me your sign-in email once you've clicked the magic link and I'll bump `profiles.role` to `admin`.
2. **Production URL** — Vercel `*.vercel.app` or custom `app.solarlink.io`? I'll add it to Supabase auth allow list.
3. **Config strategy for Vercel** — env-var build step or commit `config.js` to private repo? Env-var is cleaner if you ever go public.
4. **Resend sender domain** — `solarlink.io` or a subdomain? Needs DNS records (SPF/DKIM) ~24h before first send.
5. **Should I audit mutation write-through now?** — quick pass over the HTML to find any remaining localStorage-only writes that would silently fail across devices. ~30 min.
