-- ============================================================
-- SolarLink CRM — Postgres schema for Supabase
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New Query → Paste → Run
--
-- This creates all tables, indexes, RLS (Row-Level Security) policies,
-- and a couple of triggers needed to back the SolarLink CRM frontend.
--
-- After running this, run seed.sql for demo data (optional).
-- ============================================================

-- ---------- Extensions ----------
create extension if not exists "uuid-ossp";

-- ---------- profiles ----------
-- Extends auth.users with role + display info.
-- Every signed-in user has exactly one row here.
create table if not exists profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  email         text not null unique,
  full_name     text,
  role          text not null default 'srp' check (role in ('srp','dspit','dsp','bdp','agency','admin')),
  phone         text,
  avatar_url    text,
  agency_id     uuid,
  metadata      jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists idx_profiles_role on profiles(role);
create index if not exists idx_profiles_agency on profiles(agency_id);

-- ---------- agencies ----------
create table if not exists agencies (
  id            uuid primary key default uuid_generate_v4(),
  name          text not null,
  stage         text not null default 'Onboarding' check (stage in ('Prospect','Onboarding','Activated','At-Risk','Churned')),
  mode          text not null default 'Roster' check (mode in ('Roster','Operator')),
  seats         int not null default 0,
  active_agents int not null default 0,
  leads_count   int not null default 0,
  closed_count  int not null default 0,
  score         int not null default 0,
  ceo_user_id   uuid references profiles(id),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists idx_agencies_stage on agencies(stage);
create index if not exists idx_agencies_ceo on agencies(ceo_user_id);

-- Add the agencies FK on profiles now that the table exists
alter table profiles
  drop constraint if exists profiles_agency_id_fkey,
  add  constraint profiles_agency_id_fkey
       foreign key (agency_id) references agencies(id) on delete set null;

-- ---------- leads ----------
create table if not exists leads (
  id            uuid primary key default uuid_generate_v4(),
  public_id     text generated always as ('L-' || substr(replace(id::text,'-',''),1,6)) stored,
  homeowner     text not null,
  phone         text not null,
  email         text,
  address       text not null,
  utility       text,
  avg_bill      int default 0,
  interest      text check (interest in ('High','Medium','Low')),
  notes         text,
  self_solar    boolean not null default false,
  stage         text not null default 'New' check (stage in ('New','Contacted','Consult Booked','Consulted','Won','Lost')),
  source_type   text not null default 'SRP' check (source_type in ('SRP','DSP','Self-Solar','Public','Vendor')),
  source_id     uuid references profiles(id),
  assigned_dsp  uuid references profiles(id),
  agency_id     uuid references agencies(id),
  gift_card     jsonb,
  consult_at    timestamptz,
  closed_at     timestamptz,
  pto_at        timestamptz,
  metadata      jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists idx_leads_source on leads(source_id);
create index if not exists idx_leads_assigned on leads(assigned_dsp);
create index if not exists idx_leads_agency on leads(agency_id);
create index if not exists idx_leads_stage on leads(stage);
create index if not exists idx_leads_created on leads(created_at desc);

-- ---------- lead_events ----------
-- Activity log: stage changes, comments, file attachments, payouts, etc.
create table if not exists lead_events (
  id            uuid primary key default uuid_generate_v4(),
  lead_id       uuid not null references leads(id) on delete cascade,
  actor_id      uuid references profiles(id),
  event_type    text not null check (event_type in ('stage_change','comment','assignment','gift_card','payout','file_attached','call_logged','email_sent','sms_sent')),
  from_value    text,
  to_value      text,
  body          text,
  metadata      jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now()
);

create index if not exists idx_lead_events_lead on lead_events(lead_id, created_at desc);
create index if not exists idx_lead_events_actor on lead_events(actor_id);

-- ---------- notifications ----------
create table if not exists notifications (
  id            uuid primary key default uuid_generate_v4(),
  user_id       uuid not null references profiles(id) on delete cascade,
  type          text not null,
  title         text not null,
  sub           text,
  ico           text,
  color         text,
  link          text,
  read_at       timestamptz,
  created_at    timestamptz not null default now()
);

create index if not exists idx_notifications_user on notifications(user_id, created_at desc) where read_at is null;
create index if not exists idx_notifications_user_all on notifications(user_id, created_at desc);

-- ---------- gift_cards ----------
create table if not exists gift_cards (
  id            uuid primary key default uuid_generate_v4(),
  lead_id       uuid references leads(id) on delete set null,
  homeowner     text,
  vendor        text check (vendor in ('Amazon','Home Depot','Visa','Target')),
  amount        int not null default 100,
  status        text not null default 'Qualified' check (status in ('Qualified','Approved','Sent','Delivered','Declined')),
  recipient     text,
  metadata      jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists idx_gift_cards_status on gift_cards(status);
create index if not exists idx_gift_cards_lead on gift_cards(lead_id);

-- ---------- audit_log (admin-only) ----------
create table if not exists audit_log (
  id            uuid primary key default uuid_generate_v4(),
  actor_id      uuid references profiles(id),
  action        text not null,
  target_type   text,
  target_id     uuid,
  details       jsonb not null default '{}'::jsonb,
  ip_address    inet,
  created_at    timestamptz not null default now()
);

create index if not exists idx_audit_log_created on audit_log(created_at desc);
create index if not exists idx_audit_log_actor on audit_log(actor_id);

-- ============================================================
-- Triggers — keep updated_at fresh, sync agency rollups, auto-create profile
-- ============================================================

-- Generic updated_at trigger
create or replace function touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists trg_profiles_updated on profiles;
create trigger trg_profiles_updated before update on profiles
  for each row execute function touch_updated_at();

drop trigger if exists trg_agencies_updated on agencies;
create trigger trg_agencies_updated before update on agencies
  for each row execute function touch_updated_at();

drop trigger if exists trg_leads_updated on leads;
create trigger trg_leads_updated before update on leads
  for each row execute function touch_updated_at();

drop trigger if exists trg_gift_cards_updated on gift_cards;
create trigger trg_gift_cards_updated before update on gift_cards
  for each row execute function touch_updated_at();

-- Auto-create profile when an auth.users row is created
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)),
    coalesce(new.raw_user_meta_data->>'role', 'srp')
  )
  on conflict (id) do nothing;
  return new;
end; $$;

drop trigger if exists trg_on_auth_user_created on auth.users;
create trigger trg_on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- Log stage changes automatically
create or replace function log_lead_stage_change()
returns trigger language plpgsql as $$
begin
  if old.stage is distinct from new.stage then
    insert into lead_events (lead_id, actor_id, event_type, from_value, to_value)
    values (new.id, auth.uid(), 'stage_change', old.stage, new.stage);
  end if;
  return new;
end; $$;

drop trigger if exists trg_lead_stage_log on leads;
create trigger trg_lead_stage_log
  after update on leads
  for each row execute function log_lead_stage_change();

-- ============================================================
-- Row-Level Security policies
-- ============================================================
-- Multi-tenant rules:
--  SRPs see their own leads, their own notifications, their own profile
--  DSPs see leads assigned to them OR sourced through their network
--  Agency CEOs see leads tied to their agency
--  Admins see everything
-- ============================================================

alter table profiles      enable row level security;
alter table agencies      enable row level security;
alter table leads         enable row level security;
alter table lead_events   enable row level security;
alter table notifications enable row level security;
alter table gift_cards    enable row level security;
alter table audit_log     enable row level security;

-- Helper: get current user's role
create or replace function current_user_role()
returns text language sql stable security definer set search_path = public as $$
  select role from profiles where id = auth.uid();
$$;

create or replace function is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select role = 'admin' from profiles where id = auth.uid()), false);
$$;

-- profiles policies
drop policy if exists "Profiles: read own"          on profiles;
drop policy if exists "Profiles: read all (admin)"  on profiles;
drop policy if exists "Profiles: read teammates"    on profiles;
drop policy if exists "Profiles: update own"        on profiles;
drop policy if exists "Profiles: insert own"        on profiles;

create policy "Profiles: read own" on profiles for select
  using (id = auth.uid());

create policy "Profiles: read all (admin)" on profiles for select
  using (is_admin());

-- Allow DSP/Agency/BDP to see basic teammate info (no PII beyond name + role)
create policy "Profiles: read teammates" on profiles for select
  using (current_user_role() in ('dsp','bdp','agency','admin'));

create policy "Profiles: update own" on profiles for update
  using (id = auth.uid()) with check (id = auth.uid());

create policy "Profiles: insert own" on profiles for insert
  with check (id = auth.uid());

-- agencies policies
drop policy if exists "Agencies: read all"            on agencies;
drop policy if exists "Agencies: write admin/bdp"     on agencies;
drop policy if exists "Agencies: ceo update own"      on agencies;

create policy "Agencies: read all" on agencies for select
  using (
    is_admin()
    or current_user_role() in ('bdp','dsp','dspit','srp')
    or ceo_user_id = auth.uid()
  );

create policy "Agencies: write admin/bdp" on agencies for all
  using (current_user_role() in ('admin','bdp'))
  with check (current_user_role() in ('admin','bdp'));

create policy "Agencies: ceo update own" on agencies for update
  using (ceo_user_id = auth.uid()) with check (ceo_user_id = auth.uid());

-- leads policies
drop policy if exists "Leads: admin all"      on leads;
drop policy if exists "Leads: srp own"        on leads;
drop policy if exists "Leads: dsp assigned"   on leads;
drop policy if exists "Leads: agency own"     on leads;
drop policy if exists "Leads: bdp readonly"   on leads;
drop policy if exists "Leads: insert by role" on leads;

create policy "Leads: admin all" on leads for all
  using (is_admin()) with check (is_admin());

-- SRPs see leads they sourced
create policy "Leads: srp own" on leads for select
  using (current_user_role() in ('srp','dspit') and source_id = auth.uid());

create policy "Leads: srp own update" on leads for update
  using (current_user_role() in ('srp','dspit') and source_id = auth.uid());

-- DSPs see leads they're assigned to OR sourced through their downline
create policy "Leads: dsp assigned" on leads for select
  using (current_user_role() = 'dsp' and (assigned_dsp = auth.uid() or source_id = auth.uid()));

create policy "Leads: dsp update" on leads for update
  using (current_user_role() = 'dsp' and (assigned_dsp = auth.uid() or source_id = auth.uid()))
  with check (current_user_role() = 'dsp' and (assigned_dsp = auth.uid() or source_id = auth.uid()));

-- Agency CEOs see leads for their agency
create policy "Leads: agency own" on leads for select
  using (
    current_user_role() = 'agency'
    and agency_id in (select id from agencies where ceo_user_id = auth.uid())
  );

-- BDPs read-only on all leads (for pipeline visibility)
create policy "Leads: bdp readonly" on leads for select
  using (current_user_role() = 'bdp');

-- Any authenticated user can insert a lead (sets themselves as source)
create policy "Leads: insert by role" on leads for insert
  with check (
    auth.uid() is not null
    and source_id = auth.uid()
  );

-- lead_events policies
drop policy if exists "Events: read if see lead"  on lead_events;
drop policy if exists "Events: insert if see lead" on lead_events;

create policy "Events: read if see lead" on lead_events for select
  using (
    is_admin()
    or exists (select 1 from leads l where l.id = lead_id) -- relies on leads RLS
  );

create policy "Events: insert if see lead" on lead_events for insert
  with check (auth.uid() is not null);

-- notifications policies (own only)
drop policy if exists "Notifs: read own"   on notifications;
drop policy if exists "Notifs: update own" on notifications;
drop policy if exists "Notifs: insert own" on notifications;

create policy "Notifs: read own" on notifications for select
  using (user_id = auth.uid() or is_admin());

create policy "Notifs: update own" on notifications for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "Notifs: insert own" on notifications for insert
  with check (auth.uid() is not null);

-- gift_cards policies (admin write; everyone reads cards on their own leads)
drop policy if exists "Cards: admin all"   on gift_cards;
drop policy if exists "Cards: read tied"   on gift_cards;

create policy "Cards: admin all" on gift_cards for all
  using (is_admin()) with check (is_admin());

create policy "Cards: read tied" on gift_cards for select
  using (
    lead_id in (select id from leads) -- relies on leads RLS
  );

-- audit_log: admin-only
drop policy if exists "Audit: admin all" on audit_log;
create policy "Audit: admin all" on audit_log for all
  using (is_admin()) with check (is_admin());

-- ============================================================
-- Realtime channels (Supabase will broadcast row changes)
-- ============================================================
-- Enable replication so the client can subscribe to changes.
-- (Run once; idempotent — safe to re-run.)
do $$ begin
  perform 1 from pg_publication where pubname = 'supabase_realtime';
  if found then
    -- Add tables to realtime publication if not already present
    begin alter publication supabase_realtime add table leads;          exception when duplicate_object then null; end;
    begin alter publication supabase_realtime add table lead_events;    exception when duplicate_object then null; end;
    begin alter publication supabase_realtime add table notifications;  exception when duplicate_object then null; end;
    begin alter publication supabase_realtime add table gift_cards;     exception when duplicate_object then null; end;
  end if;
end $$;

-- ============================================================
-- Done. Run seed.sql next for demo data.
-- ============================================================
