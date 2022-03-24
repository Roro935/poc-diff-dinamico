create database zeust1;
GO
create database zeust2;
GO

use zeust1;
GO
--Crear tabla test en zeust1
create table test (id int, name VARCHAR(255), estado bit);
go

insert into test (id, name, estado) values (1, 'Juan Perez', 1), (2, 'John Doe', 1), (3, 'Santino Amigo', 1);
go

create table test2 (id int, name VARCHAR(255), estado bit);
go

insert into test2 (id, name, estado) values (1, 'Pepe Perez', 1), (2, 'John Smith', 1), (3, 'Paco Amigo', 1);
go



use zeust2
go
--Crear tabla test en zeust2
create table test (id int, name VARCHAR(255), estado bit);
go

insert into test (id, name, estado) values (1, 'Juan Perez', 1), (2, 'John Doe', 1), (3, 'Santino Amigo', 1);
go

create table test2 (id int, name VARCHAR(255), estado bit);
go

insert into test2 (id, name, estado) values (1, 'Pepe Perez', 1), (2, 'John Smith', 1), (3, 'Paco Amigo', 1);
go