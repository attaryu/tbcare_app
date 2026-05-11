-- Add auth_user_id to users table to link with Supabase Auth
alter table public.users add column if not exists auth_user_id uuid unique;

-- Enable RLS for symptom_logs
alter table public.symptom_logs enable row level security;

-- Policy: Select symptom_logs
-- Patients can see their own logs
-- Approved supervisors can see their patients' logs
create policy "select_symptom_logs" on public.symptom_logs
    for select
    using (
        treatment_period_id in (
            select id from public.treatment_periods 
            where patients_id in (select id from public.users where auth_user_id = auth.uid())
        )
        or
        treatment_period_id in (
            select tp.id 
            from public.treatment_periods tp
            join public.supervisions_patients sp on tp.patients_id = sp.patients_id
            join public.supervisions s on sp.supervision_id = s.id
            join public.users u on s.supervisor_id = u.id
            where u.auth_user_id = auth.uid()
            and sp.status = 'approved'
        )
    );

-- Policy: Insert symptom_logs
-- Only patients can insert logs for their own active treatment periods
create policy "insert_symptom_logs" on public.symptom_logs
    for insert
    with check (
        treatment_period_id in (
            select id from public.treatment_periods 
            where patients_id in (select id from public.users where auth_user_id = auth.uid())
            and status = 'active'
        )
    );

-- Policy: Update symptom_logs
-- Only patients can update their own logs
create policy "update_symptom_logs" on public.symptom_logs
    for update
    using (
        treatment_period_id in (
            select id from public.treatment_periods 
            where patients_id in (select id from public.users where auth_user_id = auth.uid())
        )
    );

-- Policy: Delete symptom_logs
-- Only patients can delete their own logs
create policy "delete_symptom_logs" on public.symptom_logs
    for delete
    using (
        treatment_period_id in (
            select id from public.treatment_periods 
            where patients_id in (select id from public.users where auth_user_id = auth.uid())
        )
    );
