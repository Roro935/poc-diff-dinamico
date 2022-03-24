use zeust2;
GO

update Articulos.Articulos set Descripcion = 'Actualizando datos' where idArticulo = 2;
GO

update Articulos.Articulos set CodigoZeus = 202202 where idArticulo = 3;
GO


delete from Articulos.ArticulosxDepositos where Articuloid = 262 and Depositoid =2;
GO

update Articulos.ArticulosxDepositos set StockMaximo = 10.000 where Articuloid = 3190 and Depositoid = 2;
GO
