do $$
begin
	create type public.supervision_status as enum ('pending', 'approved', 'rejected', 'revoked');
exception
	when duplicate_object then null;
end $$;

do $$
begin
	create type public.treatment_status as enum ('active', 'completed', 'failed');
exception
	when duplicate_object then null;
end $$;

do $$
begin
	create type public.duration_type as enum ('day', 'month');
exception
	when duplicate_object then null;
end $$;

create table public.supervisions (
	id serial primary key,
	supervisor_id integer not null unique references public.users (id) on delete cascade,
	supervision_code varchar(100) unique
);

create table public.supervisions_patients (
	id serial primary key,
	supervision_id integer not null references public.supervisions (id) on delete cascade,
	patients_id integer not null references public.users (id) on delete cascade,
	status public.supervision_status not null default 'pending',
	joined_at timestamp,
	request_at timestamp not null default now()
);

create unique index uidx_sp_one_active_supervisor_per_patient
	on public.supervisions_patients (patients_id)
	where status = 'approved';

create table public.treatment_periods (
	id serial primary key,
	patients_id integer not null references public.users (id) on delete cascade,
	name varchar(255) not null,
	start_date date not null,
	actual_end_date date,
	prediction_end_date date,
	duration integer not null,
	duration_type public.duration_type not null default 'month',
	status public.treatment_status not null default 'active'
);
