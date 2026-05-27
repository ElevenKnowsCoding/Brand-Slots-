alter table if exists public.app_config
add column if not exists apk_base_url text not null default '';

alter table if exists public.app_config
add column if not exists local_project_path text not null default '';

alter table if exists public.screens
add column if not exists play_count integer not null default 0;

alter table if exists public.screens
add column if not exists completed_rounds integer not null default 0;

alter table if exists public.screens
add column if not exists last_playback_at text;
