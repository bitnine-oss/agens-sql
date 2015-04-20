\set VERBOSITY 'terse'
set client_min_messages = 'warning';

-- test sqltriga truncate
create table trunctrg1 (
    dat1 text not null primary key,
    dat2 int2 not null,
    dat3 text
);
create trigger trunc1_trig after truncate on trunctrg1
for each statement execute procedure pgq.sqltriga('que3');
truncate trunctrg1;


-- test logutriga truncate
create table trunctrg2 (
    dat1 text not null primary key,
    dat2 int2 not null,
    dat3 text
);
create trigger trunc2_trig after truncate on trunctrg2
for each statement execute procedure pgq.logutriga('que3');
truncate trunctrg2;

-- test deny
create trigger deny_triga2 after truncate on trunctrg2
for each statement execute procedure pgq.logutriga('noqueue', 'deny');
truncate trunctrg2;

