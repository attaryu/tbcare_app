create table public.users (
	id serial primary key,
	name varchar(255) not null,
	email varchar(255) not null unique,
	telephone_number varchar(20),
	photo_url varchar(500),
	password varchar(255) not null,
	fcm_token varchar(255)
);

create table public.roles (
	id serial primary key,
	slug varchar(100) not null unique,
	name varchar(255) not null
);

create table public.permissions (
	id serial primary key,
	slug varchar(100) not null unique,
	name varchar(255) not null
);

create table public.user_roles (
	user_id integer not null references public.users (id) on delete cascade,
	role_id integer not null references public.roles (id) on delete cascade,
	primary key (user_id, role_id)
);

create table public.role_permissions (
	role_id integer not null references public.roles (id) on delete cascade,
	permission_id integer not null references public.permissions (id) on delete cascade,
	primary key (role_id, permission_id)
);
