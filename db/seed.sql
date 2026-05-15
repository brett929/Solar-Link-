-- ============================================================
-- SolarLink CRM — Demo seed data
-- ============================================================
-- Run this AFTER schema.sql.
--
-- Profiles get created automatically when users sign up (via the
-- handle_new_user trigger), so this file seeds agencies and some
-- demo leads that an admin can claim/assign later.
-- ============================================================

-- ---------- Agencies ----------
insert into agencies (id, name, stage, mode, seats, active_agents, leads_count, closed_count, score, created_at) values
  ('11111111-1111-1111-1111-111111111101', 'Sunridge Realty Group',    'Activated',         'Roster',   24, 18, 62, 21, 92, '2025-12-10'),
  ('11111111-1111-1111-1111-111111111102', 'Apex Insurance Brokers',   'Activated',         'Roster',   14,  9, 38, 11, 78, '2026-01-22'),
  ('11111111-1111-1111-1111-111111111103', 'Vista Roofing Co',         'Activated',         'Operator',  5,  5, 19,  7, 88, '2026-02-03'),
  ('11111111-1111-1111-1111-111111111104', 'Patel CPA Partners',       'Onboarding',        'Operator',  3,  2,  5,  1, 55, '2026-04-01'),
  ('11111111-1111-1111-1111-111111111105', 'Coastline Realty',         'Onboarding',        'Roster',   30,  0,  0,  0, 30, '2026-04-15')
on conflict (id) do nothing;

-- ---------- Demo leads ----------
-- Tied to an agency where appropriate; source_id/assigned_dsp left null
-- so an admin can claim them after the first round of partner signups.
insert into leads (id, homeowner, phone, email, address, utility, avg_bill, interest, notes, stage, source_type, agency_id, consult_at, created_at) values
  ('22222222-2222-2222-2222-222222222001', 'Tony Reyes',     '(480) 555-0021', 'tony.r@example.com',     '1422 Camelback Rd, Phoenix AZ',        'APS',           280, 'High',   'Very engaged, ready to schedule install',                'Consult Booked', 'SRP',    null,                                          '2026-05-08 14:00', '2026-05-01'),
  ('22222222-2222-2222-2222-222222222002', 'Brenda Liu',     '(415) 555-0488', 'b.liu@example.com',      '88 Mission St, San Francisco CA',      'PG&E',          340, 'High',   'Wants quote on Tesla Powerwall',                         'Consulted',      'SRP',    '11111111-1111-1111-1111-111111111101',        '2026-05-02 10:00', '2026-04-26'),
  ('22222222-2222-2222-2222-222222222003', 'Marcus Webb',    '(303) 555-0731', 'm.webb@example.com',     '7129 Larimer, Denver CO',              'Xcel',          220, 'High',   'Closed — install scheduled',                             'Won',            'SRP',    null,                                          '2026-04-25 13:00', '2026-04-18'),
  ('22222222-2222-2222-2222-222222222004', 'Priya Singh',    '(512) 555-0298', 'priya.s@example.com',    '2233 South Lamar, Austin TX',          'Austin Energy', 265, 'Medium', 'New lead from referral link',                            'New',            'SRP',    null,                                          null,               '2026-05-06'),
  ('22222222-2222-2222-2222-222222222005', 'Jamal Foster',   '(602) 555-0119', 'j.foster@example.com',   '9087 Camelback East, Phoenix AZ',      'APS',           195, 'Medium', 'Left voicemail, will follow up Thurs',                   'Contacted',      'SRP',    null,                                          null,               '2026-05-04'),
  ('22222222-2222-2222-2222-222222222006', 'Hannah Schmidt', '(720) 555-0911', 'h.schmidt@example.com',  '4502 Welton St, Denver CO',            'Xcel',          310, 'High',   'Referred by insurance agent',                            'Consult Booked', 'SRP',    '11111111-1111-1111-1111-111111111102',        '2026-05-09 11:00', '2026-05-02'),
  ('22222222-2222-2222-2222-222222222007', 'Robert Chen',    '(415) 555-0205', 'rchen@example.com',      '2891 Geary Blvd, San Francisco CA',    'PG&E',          410, 'High',   'Roof replacement bundled',                               'Consulted',      'SRP',    '11111111-1111-1111-1111-111111111103',        '2026-05-03 15:00', '2026-04-29'),
  ('22222222-2222-2222-2222-222222222008', 'Lily Tran',      '(813) 555-0688', 'lily.t@example.com',     '8217 Bayshore Blvd, Tampa FL',         'TECO',          175, 'Low',    'Not a fit — rental property',                            'Lost',           'SRP',    null,                                          '2026-04-28 09:30', '2026-04-20'),
  ('22222222-2222-2222-2222-222222222009', 'David Khan',     '(602) 555-0823', 'dkhan@example.com',      '12 N Central Ave, Phoenix AZ',         'SRP',           240, 'High',   'SRP submitted self-solar lead',                          'New',            'Self-Solar', null,                                       null,               '2026-05-07'),
  ('22222222-2222-2222-2222-222222222010', 'Sara Whitfield', '(512) 555-0177', 'sara.w@example.com',     '1118 East 6th, Austin TX',             'Austin Energy', 295, 'High',   'Install Q3',                                             'Won',            'SRP',    '11111111-1111-1111-1111-111111111101',        '2026-04-19 13:00', '2026-04-12'),
  ('22222222-2222-2222-2222-222222222011', 'Andre Bisset',   '(303) 555-0942', 'a.bisset@example.com',   '4810 Quebec St, Denver CO',            'Xcel',          330, 'High',   'Email sent, awaiting reply',                             'Contacted',      'SRP',    null,                                          null,               '2026-05-05'),
  ('22222222-2222-2222-2222-222222222012', 'Megan O''Brien', '(415) 555-0612', 'megan.o@example.com',    '901 Valencia St, San Francisco CA',    'PG&E',          265, 'Medium', 'Tour first home',                                        'Consult Booked', 'SRP',    null,                                          '2026-05-10 16:00', '2026-05-03')
on conflict (id) do nothing;

-- ---------- Gift cards ----------
insert into gift_cards (id, lead_id, homeowner, vendor, amount, status, created_at) values
  ('33333333-3333-3333-3333-333333333001', '22222222-2222-2222-2222-222222222002', 'Brenda Liu',     null,         100, 'Qualified', '2026-05-02'),
  ('33333333-3333-3333-3333-333333333002', '22222222-2222-2222-2222-222222222003', 'Marcus Webb',    'Amazon',     100, 'Delivered', '2026-04-25'),
  ('33333333-3333-3333-3333-333333333003', '22222222-2222-2222-2222-222222222007', 'Robert Chen',    'Home Depot', 100, 'Sent',      '2026-05-03'),
  ('33333333-3333-3333-3333-333333333004', '22222222-2222-2222-2222-222222222008', 'Lily Tran',      null,         100, 'Declined',  '2026-04-28'),
  ('33333333-3333-3333-3333-333333333005', '22222222-2222-2222-2222-222222222010', 'Sara Whitfield', 'Amazon',     100, 'Delivered', '2026-04-19')
on conflict (id) do nothing;

-- ============================================================
-- After seeding:
-- 1. Sign up your admin user via the app login screen
-- 2. In Supabase Table Editor, find your profile row in `profiles`
-- 3. Change your role from 'srp' to 'admin'
-- 4. As admin, you can now claim leads (assign source_id/assigned_dsp)
-- ============================================================
