-- Seed Roles and Permissions
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

-- Seed Users
-- Note: auth_user_id is set to a dummy UUID for local testing reference.
-- In a real Supabase environment, these should match auth.users.id.
insert into public.users (name, email, password, auth_user_id)
values
    ('Pasien Test', 'pasien@tbcare.com', '$2a$12$fD0VddZy8Gc5mh9hufMareb/b5D5QRfTpnoZkOJ6io8MevvZ5yT/y', '00000000-0000-0000-0000-000000000001'),
    ('Pengawas Test', 'pengawas@tbcare.com', '$2a$12$mpWe7xLjOycfNYx/qhWgROV.GZgCqk0DWh4RyRYxZeBkOkdeQsVv6', '00000000-0000-0000-0000-000000000002')
on conflict (email) do update set
    password = excluded.password,
    name = excluded.name;

-- Assign Roles to Users
insert into public.user_roles (user_id, role_id)
select u.id, r.id
from (values
    ('pasien@tbcare.com', 'pasien'),
    ('pengawas@tbcare.com', 'pengawas')
) as seeded(email, role_slug)
join public.users u on u.email = seeded.email
join public.roles r on r.slug = seeded.role_slug
on conflict do nothing;

-- Seed Active Treatment Period for the Patient
insert into public.treatment_periods (patients_id, name, start_date, duration, duration_type, status)
select u.id, 'Periode Pengobatan Utama', now(), 6, 'month', 'active'
from public.users u
where u.email = 'pasien@tbcare.com'
on conflict do nothing;