CREATE USER ADMIN IDENTIFIED BY "123456" default tablespace tbsp_Admin;

alter user admin quota unlimited on tbsp_admin;
grant all privileges to admin;
grant select any dictionary to admin;
grant select_catalog_role to admin;
grant select any table to admin;



create user gs
  identified by "123456"
  default tablespace YILDIZ01
  quota 10g on YILDIZ01;

GRANT CONNECT TO gs;
GRANT CREATE SESSION TO gs;

grant create table, create view, create trigger, create procedure, create sequence to gs;

GRANT
	SELECT,
	INSERT,
	UPDATE,
	DELETE
	ON
		gs.*
	TO
	gs_web;