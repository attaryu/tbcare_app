-- Migration: Add log_date column and unique constraint to compliance_logs table
ALTER TABLE public.compliance_logs 
ADD COLUMN log_date DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE public.compliance_logs 
ADD CONSTRAINT unique_schedule_log_date UNIQUE (schedule_id, log_date);
