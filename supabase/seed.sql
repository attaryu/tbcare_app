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