--modificar datos de zeust2
use zeust2;
go

delete from test where id = 2;
go

update test set name = 'Santino Enemigo' where id = 3;
go

update test set estado= 0 where id = 1;
go


insert into test (id, name,estado) values (4, 'Fiesta Bizarra', 1), (5, 'Wanderlust', 1), (6, 'Suerte Campeon', 1);
go



delete from test2 where id = 1;
go

update test2 set name = 'Paco Enemigo' where id = 3;
go

update test2 set estado= 0 where id = 2;
go

insert into test2 (id, name,estado) values (4, 'Fiesta Bizarra', 1), (5, 'Wanderlust', 1), (6, 'Suerte Campeon', 1);
go