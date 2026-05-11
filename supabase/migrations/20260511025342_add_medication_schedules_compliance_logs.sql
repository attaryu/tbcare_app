do $$
begin
	create type public.compliance_status as enum ('pending', 'taken', 'missed');
exception
	when duplicate_object then null;
end $$;

create table public.medication_schedules (
	id serial primary key,
	treatment_period_id integer not null references public.treatment_periods (id) on delete cascade,
	med_name varchar(255) not null,
	schedule_time time not null
);

create table public.compliance_logs (
	id serial primary key,
	schedule_id integer not null references public.medication_schedules (id) on delete cascade,
	med_name varchar(255) not null,
	photo_url varchar(500),
	taken_at timestamp,
	status public.compliance_status not null default 'pending',
	verified_by integer references public.users (id) on delete set null
);
