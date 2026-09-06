begin;

create table public.player_progress (
    user_id uuid not null
        primary key
        references auth.users (id)
        on delete cascade,
    minerals_ship integer not null default 0
        check (minerals_ship >= 0),
    minerals_rover integer not null default 0
        check (minerals_rover >= 0),
    map_tier smallint not null default 0
        check (map_tier >= 0),
    unlocked_syntax jsonb not null default '{
        "for": false,
        "while": false,
        "if": false,
        "else": false,
        "in range": false
    }'::jsonb
        check (jsonb_typeof(unlocked_syntax) = 'object'),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create function public.set_player_progress_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger set_player_progress_updated_at
before update on public.player_progress
for each row
execute function public.set_player_progress_updated_at();

alter table public.player_progress enable row level security;

create policy "Users can read their own progress"
on public.player_progress
for select
to authenticated
using (auth.uid() = user_id);

create policy "Users can create their own progress"
on public.player_progress
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "Users can update their own progress"
on public.player_progress
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

revoke all on table public.player_progress from anon;
revoke all on table public.player_progress from authenticated;
grant select, insert, update on table public.player_progress to authenticated;

revoke all on function public.set_player_progress_updated_at() from public;
revoke all on function public.set_player_progress_updated_at() from anon;
revoke all on function public.set_player_progress_updated_at() from authenticated;

commit;
