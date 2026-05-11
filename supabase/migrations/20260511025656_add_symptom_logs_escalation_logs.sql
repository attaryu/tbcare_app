do $$
begin
	create type public.symptom_level as enum ('normal', 'mild', 'severe');
exception
	when duplicate_object then null;
end $$;

do $$
begin
	create type public.escalation_status as enum ('triggered', 'resolved', 'ignored');
exception
	when duplicate_object then null;
end $$;

create table public.symptom_logs (
	id serial primary key,
	treatment_period_id integer not null references public.treatment_periods (id) on delete cascade,
	level public.symptom_level not null default 'normal',
	note text,
	created_at timestamp not null default now(),
	edited_at timestamp
);

create table public.escalation_logs (
	id serial primary key,
	compliance_log_id integer not null references public.compliance_logs (id) on delete cascade,
	status public.escalation_status not null default 'triggered',
	action_note text,
	handled_by integer references public.users (id) on delete set null,
	created_at timestamp not null default now(),
	resolved_at timestamp
);
