

\set ECHO none
set log_error_verbosity = 'terse';
set client_min_messages = 'warning';
\set ECHO all

drop role if exists londiste_test_part1;
drop role if exists londiste_test_part2;
create group londiste_test_part1;
create group londiste_test_part2;

create table events (
    id int4 primary key,
    txt text not null,
    ctime timestamptz not null default now(),
    someval int4 check (someval > 0)
);
create index ctime_idx on events (ctime);

create rule ignore_dups AS
    on insert to events
    where (exists (select 1 from events
                   where (events.id = new.id)))
    do instead nothing;


create or replace function "NullTrigger"() returns trigger as $$
begin
    return null;
end; $$ language plpgsql;

create trigger "Fooza" after delete on events for each row execute procedure "NullTrigger"();
alter table events enable always trigger "Fooza";

grant select,delete on events to londiste_test_part1;
grant select,update,delete on events to londiste_test_part2 with grant option;
grant select,insert on events to public;

select londiste.create_partition('events', 'events_2011_01', 'id', 'ctime', '2011-01-01', 'month');
select londiste.create_partition('events', 'events_2011_01', 'id', 'ctime', '2011-01-01'::timestamptz, 'month');
select londiste.create_partition('events', 'events_2011_01', 'id', 'ctime', '2011-01-01'::timestamp, 'month');

select count(*) from pg_indexes where schemaname='public' and tablename = 'events_2011_01';
select count(*) from pg_constraint where conrelid = 'public.events_2011_01'::regclass;
select count(*) from pg_rules where schemaname = 'public' and tablename = 'events_2011_01';
select trigger_name, event_manipulation, action_statement
    from information_schema.triggers
    where event_object_schema = 'public' and event_object_table = 'events_2011_01';
select tgenabled, pg_get_triggerdef(oid) from pg_trigger where tgrelid = 'events_2011_01'::regclass::oid;

-- test weird quoting

create table "Bad "" table '.' name!" (
    id int4 primary key,
    txt text not null,
    ctime timestamptz not null default now(),
    someval int4 check (someval > 0)
);
create rule "Ignore Dups" AS
    on insert to "Bad "" table '.' name!"
    where (exists (select 1 from "Bad "" table '.' name!"
                   where ("Bad "" table '.' name!".id = new.id)))
    do instead nothing;
alter table "Bad "" table '.' name!" ENABLE ALWAYS RULE "Ignore Dups";
select londiste.create_partition('public.Bad " table ''.'' name!', 'public.Bad " table ''.'' part!', 'id', 'ctime', '2011-01-01', 'month');
select count(*) from pg_rules where schemaname = 'public' and tablename ilike 'bad%';

-- \d events_2011_01
-- \dp events
-- \dp events_2011_01

