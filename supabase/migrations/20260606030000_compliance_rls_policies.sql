-- Migration: Enable RLS on compliance_logs and add policies for patients and supervisors

ALTER TABLE public.compliance_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Select compliance_logs
-- Patients can see their own compliance logs
-- Approved supervisors can see their patients' compliance logs
CREATE POLICY "select_compliance_logs" ON public.compliance_logs
    FOR SELECT
    USING (
        schedule_id IN (
            SELECT ms.id FROM public.medication_schedules ms
            JOIN public.treatment_periods tp ON ms.treatment_period_id = tp.id
            WHERE tp.patients_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid())
        )
        OR
        schedule_id IN (
            SELECT ms.id FROM public.medication_schedules ms
            JOIN public.treatment_periods tp ON ms.treatment_period_id = tp.id
            JOIN public.supervisions_patients sp ON tp.patients_id = sp.patients_id
            JOIN public.supervisions s ON sp.supervision_id = s.id
            JOIN public.users u ON s.supervisor_id = u.id
            WHERE u.auth_user_id = auth.uid()
            AND sp.status = 'approved'
        )
    );

-- Policy: Insert compliance_logs
-- Patients can insert their own compliance logs
CREATE POLICY "insert_compliance_logs" ON public.compliance_logs
    FOR INSERT
    WITH CHECK (
        schedule_id IN (
            SELECT ms.id FROM public.medication_schedules ms
            JOIN public.treatment_periods tp ON ms.treatment_period_id = tp.id
            WHERE tp.patients_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid())
            AND tp.status = 'active'
        )
    );

-- Policy: Update compliance_logs
-- Patients can update their own compliance logs (e.g. taking meds, uploading photo evidence)
-- Supervisors can update compliance logs of their approved patients (e.g. verifying/rejecting logs)
CREATE POLICY "update_compliance_logs" ON public.compliance_logs
    FOR UPDATE
    USING (
        schedule_id IN (
            SELECT ms.id FROM public.medication_schedules ms
            JOIN public.treatment_periods tp ON ms.treatment_period_id = tp.id
            WHERE tp.patients_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid())
        )
        OR
        schedule_id IN (
            SELECT ms.id FROM public.medication_schedules ms
            JOIN public.treatment_periods tp ON ms.treatment_period_id = tp.id
            JOIN public.supervisions_patients sp ON tp.patients_id = sp.patients_id
            JOIN public.supervisions s ON sp.supervision_id = s.id
            JOIN public.users u ON s.supervisor_id = u.id
            WHERE u.auth_user_id = auth.uid()
            AND sp.status = 'approved'
        )
    );

-- Policy: Delete compliance_logs
-- Patients can delete their own compliance logs
CREATE POLICY "delete_compliance_logs" ON public.compliance_logs
    FOR DELETE
    USING (
        schedule_id IN (
            SELECT ms.id FROM public.medication_schedules ms
            JOIN public.treatment_periods tp ON ms.treatment_period_id = tp.id
            WHERE tp.patients_id IN (SELECT id FROM public.users WHERE auth_user_id = auth.uid())
        )
    );
