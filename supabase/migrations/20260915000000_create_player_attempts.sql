begin;

create table public.player_attempts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null
        references auth.users (id)
        on delete cascade,
    duration_seconds double precision not null
        check (duration_seconds >= 0),
    objective_id text not null,
    execution_success boolean not null,
    objective_completed boolean not null,
    error_type text not null default '',
    created_at timestamptz not null default now()
);

alter table public.player_attempts enable row level security;

create policy "Users can read their own attempts"
on public.player_attempts
for select
to authenticated
using (auth.uid() = user_id);

create policy "Users can create their own attempts"
on public.player_attempts
for insert
to authenticated
with check (auth.uid() = user_id);

revoke all on table public.player_attempts from anon;
revoke all on table public.player_attempts from authenticated;
grant select, insert on table public.player_attempts to authenticated;

commit;
