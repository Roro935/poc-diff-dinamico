> La POC de los backups diferenciales está en la rama `differential`

# Run
Para correr el contenedor ejecutar el comando:
```sh
make run
```
Esto transformará todas las tablas en el archivo `BackFranquiciasDW16112020.bak` a archivos csv dentro de la carpeta exports. Toda la lógica se encuentra en el `create-csvs.sh`


Para conectarse al contenedor ejecutar el comando:
```sh
docker exec -i -t 25b3d2d3f6c1 /bin/bash
```
donde se remplaza el id por el id correspondiente del contenedor o su nombre
Se puede obtener el id on el comando 
```sh
docker ps
```

Para entrar al promt de sql se debe ejecutar el siguiente comando:
```sh
/opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD
```


