-- Disable RLS on all tables to support manual authentication (testing only)
alter table public.users disable row level security;
alter table public.roles disable row level security;
alter table public.permissions disable row level security;
alter table public.user_roles disable row level security;
alter table public.role_permissions disable row level security;
alter table public.supervisions disable row level security;
alter table public.supervisions_patients disable row level security;
alter table public.treatment_periods disable row level security;
alter table public.medication_schedules disable row level security;
alter table public.compliance_logs disable row level security;
alter table public.symptom_logs disable row level security;
alter table public.escalation_logs disable row level security;
