-- rambler up

create or replace function updated_at_trigger() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language 'plpgsql';

create table users (
  id serial not null primary key,
  email varchar(500) not null unique,
  password char(60) not null,
  name varchar(500),
  is_admin bool default false,
  created_at timestamp not null default now(),
  updated_at timestamp not null default now()
);

create trigger updated_at before update
    on users for each row execute procedure updated_at_trigger();

-- rambler down

drop table users;

drop function if exists updated_at_trigger();
