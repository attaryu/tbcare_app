-- Clean all existing data to ensure a fresh seeding process
truncate public.escalation_logs cascade;
truncate public.compliance_logs cascade;
truncate public.symptom_logs cascade;
truncate public.medication_schedules cascade;
truncate public.treatment_periods cascade;
truncate public.supervisions_patients cascade;
truncate public.supervisions cascade;
truncate public.user_roles cascade;
truncate public.role_permissions cascade;
truncate public.users cascade;
truncate public.roles cascade;
truncate public.permissions cascade;

-- Clean auth schema tables (requires running as superuser/postgres)
truncate auth.users cascade;

-- Enable pgcrypto extension for crypt and gen_salt
create extension if not exists pgcrypto;

-- 1. Seed Roles and Permissions
insert into public.roles (slug, name)
values
    ('pasien', 'Pasien'),
    ('pengawas', 'Pengawas')
on conflict (slug) do nothing;

insert into public.permissions (slug, name)
values
    ('view_patient_history', 'Lihat Riwayat Pasien'),
    ('approve_supervision', 'Setujui Pengawasan'),
    ('reject_supervision', 'Tolak Pengawasan'),
    ('view_compliance_log', 'Lihat Log Kepatuhan'),
    ('upload_photo_evidence', 'Unggah Bukti Foto'),
    ('manage_treatment_period', 'Kelola Periode Pengobatan'),
    ('manage_medication_schedule', 'Kelola Jadwal Obat')
on conflict (slug) do nothing;

insert into public.role_permissions (role_id, permission_id)
select roles.id, permissions.id
from (values
    ('pengawas', 'view_patient_history'),
    ('pengawas', 'approve_supervision'),
    ('pengawas', 'reject_supervision'),
    ('pengawas', 'view_compliance_log'),
    ('pasien', 'upload_photo_evidence'),
    ('pasien', 'manage_treatment_period'),
    ('pasien', 'manage_medication_schedule')
) as seeded(role_slug, permission_slug)
join public.roles on roles.slug = seeded.role_slug
join public.permissions on permissions.slug = seeded.permission_slug
on conflict do nothing;

-- 2. Insert into Supabase auth.users
insert into auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    role,
    aud,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change,
    phone_change,
    phone_change_token,
    email_change_token_current,
    reauthentication_token,
    is_sso_user,
    is_anonymous
) values
(
    'e0000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000000',
    'budi.santoso@tbcare.com',
    crypt('password', gen_salt('bf', 10)),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"name":"Budi Santoso"}',
    false,
    'authenticated',
    'authenticated',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    false,
    false
),
(
    'e0000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000000',
    'rina.wulandari@tbcare.com',
    crypt('password', gen_salt('bf', 10)),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"name":"Rina Wulandari"}',
    false,
    'authenticated',
    'authenticated',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    false,
    false
),
(
    'e0000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000000',
    'dika.prasetyo@tbcare.com',
    crypt('password', gen_salt('bf', 10)),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"name":"Dika Prasetyo"}',
    false,
    'authenticated',
    'authenticated',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    false,
    false
),
(
    'e0000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000000',
    'ahmad.hidayat@tbcare.com',
    crypt('password', gen_salt('bf', 10)),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"name":"Ahmad Hidayat"}',
    false,
    'authenticated',
    'authenticated',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    false,
    false
);

-- 3. Insert into Supabase auth.identities
insert into auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
) values
(
    'e0000000-0000-0000-0000-000000000001',
    'e0000000-0000-0000-0000-000000000001',
    jsonb_build_object('sub', 'e0000000-0000-0000-0000-000000000001', 'email', 'budi.santoso@tbcare.com', 'email_verified', true),
    'email',
    'budi.santoso@tbcare.com',
    now(),
    now(),
    now()
),
(
    'e0000000-0000-0000-0000-000000000002',
    'e0000000-0000-0000-0000-000000000002',
    jsonb_build_object('sub', 'e0000000-0000-0000-0000-000000000002', 'email', 'rina.wulandari@tbcare.com', 'email_verified', true),
    'email',
    'rina.wulandari@tbcare.com',
    now(),
    now(),
    now()
),
(
    'e0000000-0000-0000-0000-000000000003',
    'e0000000-0000-0000-0000-000000000003',
    jsonb_build_object('sub', 'e0000000-0000-0000-0000-000000000003', 'email', 'dika.prasetyo@tbcare.com', 'email_verified', true),
    'email',
    'dika.prasetyo@tbcare.com',
    now(),
    now(),
    now()
),
(
    'e0000000-0000-0000-0000-000000000004',
    'e0000000-0000-0000-0000-000000000004',
    jsonb_build_object('sub', 'e0000000-0000-0000-0000-000000000004', 'email', 'ahmad.hidayat@tbcare.com', 'email_verified', true),
    'email',
    'ahmad.hidayat@tbcare.com',
    now(),
    now(),
    now()
);

-- 4. Insert into public.users with matching auth_user_id
insert into public.users (name, email, auth_user_id, telephone_number)
values
    ('Budi Santoso', 'budi.santoso@tbcare.com', 'e0000000-0000-0000-0000-000000000001', '081234567890'),
    ('Rina Wulandari', 'rina.wulandari@tbcare.com', 'e0000000-0000-0000-0000-000000000002', '081234567891'),
    ('Dika Prasetyo', 'dika.prasetyo@tbcare.com', 'e0000000-0000-0000-0000-000000000003', '081234567892'),
    ('Ahmad Hidayat', 'ahmad.hidayat@tbcare.com', 'e0000000-0000-0000-0000-000000000004', '081234567893');

-- 5. Map Roles to Users in user_roles
insert into public.user_roles (user_id, role_id)
select u.id, r.id
from (values
    ('budi.santoso@tbcare.com', 'pengawas'),
    ('rina.wulandari@tbcare.com', 'pasien'),
    ('dika.prasetyo@tbcare.com', 'pasien'),
    ('ahmad.hidayat@tbcare.com', 'pasien')
) as seeded(email, role_slug)
join public.users u on u.email = seeded.email
join public.roles r on r.slug = seeded.role_slug;

-- 6. Setup Supervision for Budi Santoso
insert into public.supervisions (supervisor_id, supervision_code)
select u.id, 'TBC-BUDI01'
from public.users u
where u.email = 'budi.santoso@tbcare.com';

-- 7. Approve Supervision requests from Rina and Dika
insert into public.supervisions_patients (supervision_id, patients_id, status, joined_at, request_at)
select 
    s.id, 
    u.id, 
    'approved'::supervision_status, 
    '2026-04-10 10:00:00'::timestamp,
    '2026-04-09 09:00:00'::timestamp
from public.supervisions s
cross join public.users u
where s.supervisor_id = (select id from public.users where email = 'budi.santoso@tbcare.com')
  and u.email = 'rina.wulandari@tbcare.com';

insert into public.supervisions_patients (supervision_id, patients_id, status, joined_at, request_at)
select 
    s.id, 
    u.id, 
    'approved'::supervision_status, 
    '2026-05-12 11:00:00'::timestamp,
    '2026-05-11 08:30:00'::timestamp
from public.supervisions s
cross join public.users u
where s.supervisor_id = (select id from public.users where email = 'budi.santoso@tbcare.com')
  and u.email = 'dika.prasetyo@tbcare.com';

insert into public.supervisions_patients (supervision_id, patients_id, status, joined_at, request_at)
select 
    s.id, 
    u.id, 
    'approved'::supervision_status, 
    '2026-05-22 09:30:00'::timestamp,
    '2026-05-21 14:15:00'::timestamp
from public.supervisions s
cross join public.users u
where s.supervisor_id = (select id from public.users where email = 'budi.santoso@tbcare.com')
  and u.email = 'ahmad.hidayat@tbcare.com';

-- 8. Seed Treatment Periods
-- Rina Wulandari: Started April 7, 2026 (~2 months ago), ends July 7, 2026 (1 month left)
insert into public.treatment_periods (patients_id, name, start_date, prediction_end_date, duration, duration_type, status)
select 
    u.id, 
    'Periode Pengobatan Utama', 
    '2026-04-07'::date, 
    '2026-07-07'::date, 
    3, 
    'month'::duration_type, 
    'active'::treatment_status
from public.users u
where u.email = 'rina.wulandari@tbcare.com';

-- Dika Prasetyo: Started May 10, 2026 (~1 month ago), ends August 10, 2026 (2 months left)
insert into public.treatment_periods (patients_id, name, start_date, prediction_end_date, duration, duration_type, status)
select 
    u.id, 
    'Periode Pengobatan Utama', 
    '2026-05-10'::date, 
    '2026-08-10'::date, 
    3, 
    'month'::duration_type, 
    'active'::treatment_status
from public.users u
where u.email = 'dika.prasetyo@tbcare.com';

-- Ahmad Hidayat: Started May 20, 2026 (~2.5 weeks ago), ends August 20, 2026 (remaining ~2.2 months)
insert into public.treatment_periods (patients_id, name, start_date, prediction_end_date, duration, duration_type, status)
select 
    u.id, 
    'Periode Pengobatan Utama', 
    '2026-05-20'::date, 
    '2026-08-20'::date, 
    3, 
    'month'::duration_type, 
    'active'::treatment_status
from public.users u
where u.email = 'ahmad.hidayat@tbcare.com';

-- 9. Seed Medication Schedules
-- Schedules for Rina Wulandari
insert into public.medication_schedules (treatment_period_id, med_name, schedule_time)
select tp.id, 'Isoniazid (INH) 300mg', '08:00:00'::time
from public.treatment_periods tp
join public.users u on tp.patients_id = u.id
where u.email = 'rina.wulandari@tbcare.com';

insert into public.medication_schedules (treatment_period_id, med_name, schedule_time)
select tp.id, 'Rifampisin 450mg', '08:00:00'::time
from public.treatment_periods tp
join public.users u on tp.patients_id = u.id
where u.email = 'rina.wulandari@tbcare.com';

insert into public.medication_schedules (treatment_period_id, med_name, schedule_time)
select tp.id, 'Pyrazinamide 1000mg', '20:00:00'::time
from public.treatment_periods tp
join public.users u on tp.patients_id = u.id
where u.email = 'rina.wulandari@tbcare.com';

-- Schedules for Dika Prasetyo
insert into public.medication_schedules (treatment_period_id, med_name, schedule_time)
select tp.id, 'Ethambutol 1000mg', '07:30:00'::time
from public.treatment_periods tp
join public.users u on tp.patients_id = u.id
where u.email = 'dika.prasetyo@tbcare.com';

insert into public.medication_schedules (treatment_period_id, med_name, schedule_time)
select tp.id, 'Streptomycin 750mg', '19:00:00'::time
from public.treatment_periods tp
join public.users u on tp.patients_id = u.id
where u.email = 'dika.prasetyo@tbcare.com';

-- Schedules for Ahmad Hidayat
insert into public.medication_schedules (treatment_period_id, med_name, schedule_time)
select tp.id, 'Isoniazid (INH) 300mg', '08:30:00'::time
from public.treatment_periods tp
join public.users u on tp.patients_id = u.id
where u.email = 'ahmad.hidayat@tbcare.com';

insert into public.medication_schedules (treatment_period_id, med_name, schedule_time)
select tp.id, 'Rifampisin 450mg', '08:30:00'::time
from public.treatment_periods tp
join public.users u on tp.patients_id = u.id
where u.email = 'ahmad.hidayat@tbcare.com';

-- 10. Seed Compliance Logs
-- Compliance Logs for Rina Wulandari (April 7, 2026 to June 6, 2026)
with rina_data as (
    select 
        u.id as patient_id,
        (select id from public.users where email = 'budi.santoso@tbcare.com') as supervisor_id,
        tp.id as tp_id
    from public.users u
    join public.treatment_periods tp on tp.patients_id = u.id
    where u.email = 'rina.wulandari@tbcare.com'
),
rina_series as (
    select 
        ms.id as schedule_id,
        ms.med_name,
        ms.schedule_time,
        d.log_date
    from public.medication_schedules ms
    cross join generate_series('2026-04-07'::date, '2026-06-06'::date, '1 day'::interval) as d(log_date)
    where ms.treatment_period_id = (select tp_id from rina_data)
),
rina_logs as (
    select
        schedule_id,
        med_name,
        log_date,
        schedule_time,
        case 
            -- Today (2026-06-06)
            when log_date = '2026-06-06' then
                case 
                    when med_name = 'Isoniazid (INH) 300mg' then 'taken'::compliance_status
                    when med_name = 'Rifampisin 450mg' then 'taken'::compliance_status
                    else 'pending'::compliance_status
                end
            -- Missed doses: every 9th day for morning meds, every 13th day for evening meds
            when (extract(day from log_date)::int % 9) = 0 and schedule_time = '08:00:00'::time then
                'missed'::compliance_status
            when (extract(day from log_date)::int % 13) = 0 and schedule_time = '20:00:00'::time then
                'missed'::compliance_status
            else
                'taken'::compliance_status
        end as status
    from rina_series
)
insert into public.compliance_logs (schedule_id, med_name, photo_url, taken_at, log_date, status, verified_by)
select 
    rl.schedule_id,
    rl.med_name,
    case 
        when rl.status = 'taken' then 'https://zncqojqhucivhmaeitkk.supabase.co/storage/v1/object/public/evidence/rina_evidence_placeholder.jpg'
        else null
    end as photo_url,
    case 
        when rl.status = 'taken' then (rl.log_date + rl.schedule_time + '5 minutes'::interval)::timestamp
        else null
    end as taken_at,
    rl.log_date,
    rl.status,
    case 
        when rl.status = 'taken' and not (rl.log_date = '2026-06-06' and rl.med_name = 'Rifampisin 450mg') then (select supervisor_id from rina_data)
        else null
    end as verified_by
from rina_logs rl;

-- Compliance Logs for Dika Prasetyo (May 10, 2026 to June 6, 2026)
with dika_data as (
    select 
        u.id as patient_id,
        (select id from public.users where email = 'budi.santoso@tbcare.com') as supervisor_id,
        tp.id as tp_id
    from public.users u
    join public.treatment_periods tp on tp.patients_id = u.id
    where u.email = 'dika.prasetyo@tbcare.com'
),
dika_series as (
    select 
        ms.id as schedule_id,
        ms.med_name,
        ms.schedule_time,
        d.log_date
    from public.medication_schedules ms
    cross join generate_series('2026-05-10'::date, '2026-06-06'::date, '1 day'::interval) as d(log_date)
    where ms.treatment_period_id = (select tp_id from dika_data)
),
dika_logs as (
    select
        schedule_id,
        med_name,
        log_date,
        schedule_time,
        case 
            -- Today (2026-06-06)
            when log_date = '2026-06-06' then
                case 
                    when med_name = 'Ethambutol 1000mg' then 'missed'::compliance_status
                    else 'pending'::compliance_status
                end
            -- Missed doses: every 7th day for evening meds, every 11th day for morning meds
            when (extract(day from log_date)::int % 7) = 0 and schedule_time = '19:00:00'::time then
                'missed'::compliance_status
            when (extract(day from log_date)::int % 11) = 0 and schedule_time = '07:30:00'::time then
                'missed'::compliance_status
            else
                'taken'::compliance_status
        end as status
    from dika_series
)
insert into public.compliance_logs (schedule_id, med_name, photo_url, taken_at, log_date, status, verified_by)
select 
    dl.schedule_id,
    dl.med_name,
    case 
        when dl.status = 'taken' then 'https://zncqojqhucivhmaeitkk.supabase.co/storage/v1/object/public/evidence/dika_evidence_placeholder.jpg'
        else null
    end as photo_url,
    case 
        when dl.status = 'taken' then (dl.log_date + dl.schedule_time + '10 minutes'::interval)::timestamp
        else null
    end as taken_at,
    dl.log_date,
    dl.status,
    case 
        when dl.status = 'taken' then (select supervisor_id from dika_data)
        else null
    end as verified_by
from dika_logs dl;

-- Compliance Logs for Ahmad Hidayat (May 20, 2026 to June 6, 2026)
with ahmad_data as (
    select 
        u.id as patient_id,
        (select id from public.users where email = 'budi.santoso@tbcare.com') as supervisor_id,
        tp.id as tp_id
    from public.users u
    join public.treatment_periods tp on tp.patients_id = u.id
    where u.email = 'ahmad.hidayat@tbcare.com'
),
ahmad_series as (
    select 
        ms.id as schedule_id,
        ms.med_name,
        ms.schedule_time,
        d.log_date
    from public.medication_schedules ms
    cross join generate_series('2026-05-20'::date, '2026-06-06'::date, '1 day'::interval) as d(log_date)
    where ms.treatment_period_id = (select tp_id from ahmad_data)
),
ahmad_logs as (
    select
        schedule_id,
        med_name,
        log_date,
        schedule_time,
        case 
            -- Today (2026-06-06)
            when log_date = '2026-06-06' then
                case 
                    when med_name = 'Isoniazid (INH) 300mg' then 'taken'::compliance_status
                    else 'pending'::compliance_status
                end
            -- Missed doses: every 8th day
            when (extract(day from log_date)::int % 8) = 0 then
                'missed'::compliance_status
            else
                'taken'::compliance_status
        end as status
    from ahmad_series
)
insert into public.compliance_logs (schedule_id, med_name, photo_url, taken_at, log_date, status, verified_by)
select 
    al.schedule_id,
    al.med_name,
    case 
        when al.status = 'taken' then 'https://zncqojqhucivhmaeitkk.supabase.co/storage/v1/object/public/evidence/ahmad_evidence_placeholder.jpg'
        else null
    end as photo_url,
    case 
        when al.status = 'taken' then (al.log_date + al.schedule_time + '12 minutes'::interval)::timestamp
        else null
    end as taken_at,
    al.log_date,
    al.status,
    case 
        when al.status = 'taken' and not (al.log_date = '2026-06-06') then (select supervisor_id from ahmad_data)
        else null
    end as verified_by
from ahmad_logs al;

-- 11. Seed Symptom Logs
-- Symptom Logs for Rina Wulandari
insert into public.symptom_logs (treatment_period_id, level, note, created_at)
select 
    tp.id,
    s.level::symptom_level,
    s.note,
    s.created_at::timestamp
from public.treatment_periods tp
join public.users u on tp.patients_id = u.id
cross join (values
    ('normal', 'Hari ke-4, belum ada keluhan berat, sedikit mual setelah minum Rifampisin.', '2026-04-10 09:30:00'),
    ('mild', 'Pusing ringan di pagi hari.', '2026-04-18 10:15:00'),
    ('severe', 'Mual muntah hebat, tidak nafsu makan seharian.', '2026-04-27 14:00:00'),
    ('mild', 'Kulit terasa agak gatal dan kemerahan.', '2026-05-05 08:45:00'),
    ('normal', 'Kondisi stabil, efek samping berkurang.', '2026-05-12 11:30:00'),
    ('severe', 'Nyeri sendi yang cukup mengganggu di lutut dan pergelangan kaki.', '2026-05-21 16:20:00'),
    ('mild', 'Urine berwarna kemerahan (normal efek Rifampisin, tapi tetap dicatat).', '2026-05-29 09:00:00'),
    ('normal', 'Sudah terbiasa dengan jadwal minum obat, kondisi tubuh membaik.', '2026-06-03 10:00:00'),
    ('normal', 'Hari ini merasa sehat.', '2026-06-06 08:30:00')
) as s(level, note, created_at)
where u.email = 'rina.wulandari@tbcare.com';

-- Symptom Logs for Dika Prasetyo
insert into public.symptom_logs (treatment_period_id, level, note, created_at)
select 
    tp.id,
    s.level::symptom_level,
    s.note,
    s.created_at::timestamp
from public.treatment_periods tp
join public.users u on tp.patients_id = u.id
cross join (values
    ('normal', 'Mulai terapi obat, mual sedikit.', '2026-05-12 08:30:00'),
    ('mild', 'Kesemutan ringan pada jari tangan.', '2026-05-18 09:45:00'),
    ('mild', 'Sedikit pusing sehabis minum obat pagi.', '2026-05-25 10:15:00'),
    ('severe', 'Pandangan agak buram/kabur setelah minum Ethambutol.', '2026-05-28 14:00:00'),
    ('mild', 'Pusing dan lemas di siang hari.', '2026-06-02 13:30:00'),
    ('normal', 'Sudah kontrol ke puskesmas, kondisi aman.', '2026-06-05 11:00:00')
) as s(level, note, created_at)
where u.email = 'dika.prasetyo@tbcare.com';

-- Symptom Logs for Ahmad Hidayat
insert into public.symptom_logs (treatment_period_id, level, note, created_at)
select 
    tp.id,
    s.level::symptom_level,
    s.note,
    s.created_at::timestamp
from public.treatment_periods tp
join public.users u on tp.patients_id = u.id
cross join (values
    ('normal', 'Mulai terapi obat Isoniazid & Rifampisin.', '2026-05-22 09:00:00'),
    ('mild', 'Nafsu makan sedikit menurun dan mual ringan.', '2026-05-27 12:30:00'),
    ('mild', 'Pusing setelah minum obat pagi hari.', '2026-06-01 10:00:00'),
    ('normal', 'Kondisi membaik, tidak ada mual lagi.', '2026-06-05 08:30:00')
) as s(level, note, created_at)
where u.email = 'ahmad.hidayat@tbcare.com';

-- 12. Seed Escalation Logs
insert into public.escalation_logs (compliance_log_id, status, action_note, handled_by, created_at, resolved_at)
select 
    cl.id as compliance_log_id,
    case 
        -- Recent logs (triggered)
        when cl.log_date >= '2026-06-03'::date then 'triggered'::escalation_status
        -- Alternating older logs
        when (extract(day from cl.log_date)::int % 2) = 0 then 'resolved'::escalation_status
        else 'ignored'::escalation_status
    end as status,
    case 
        when cl.log_date >= '2026-06-03'::date then null
        when (extract(day from cl.log_date)::int % 2) = 0 then 'Sudah dihubungi via WA, pasien lupa karena ketiduran.'
        else 'Diabaikan, pasien mengonfirmasi minum obat terlambat secara mandiri.'
    end as action_note,
    case 
        when cl.log_date >= '2026-06-03'::date then null
        else (select id from public.users where email = 'budi.santoso@tbcare.com')
    end as handled_by,
    (cl.log_date + (select schedule_time from public.medication_schedules where id = cl.schedule_id) + '2 hours'::interval)::timestamp as created_at,
    case 
        when cl.log_date >= '2026-06-03'::date then null
        else (cl.log_date + (select schedule_time from public.medication_schedules where id = cl.schedule_id) + '3 hours 15 minutes'::interval)::timestamp
    end as resolved_at
from public.compliance_logs cl
where cl.status = 'missed';
