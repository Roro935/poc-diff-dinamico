#crear bds
/opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -i "/create.sql"

#modificar datos
/opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -i "/modify.sql"

#Extraer todas las tablas de las bd's
echo "Exploring tables from DB..."
mkdir /mnt/external/exports

/opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -s. -h -1 -m 1 -W -Q "SET NOCOUNT ON; USE zeust1; SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES" > /mnt/external/exports/tables1.txt

/opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -s. -h -1 -m 1 -W -Q "SET NOCOUNT ON; use zeust2; SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES" > /mnt/external/exports/tables2.txt


#se podria hacer una iteracion previa que valide que hay igual cantidad de tablas en ambas bds para poder continuar\
#caso contrario se envia mensaje de error indicando que faltan tablaas

#iterar por cada tabla que se encuentre en los archivos txt, se asume que tienen igual cantidad de tablas
#no se eliminan tablas
for table in $(cat /mnt/external/exports/tables1.txt); do
    schema_name="${table%.*}"
    table_name="${table#*.}"

    columns_query="SET NOCOUNT ON; USE zeust1; SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='$table_name' AND TABLE_SCHEMA='$schema_name'"
    /opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -s, -h -1 -m 1 -W -Q "$columns_query" > /mnt/external/exports/columns.csv

    query="SET NOCOUNT ON; USE zeust1 ; SELECT SUBSTRING((SELECT ','+ COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='$table_name' AND TABLE_SCHEMA='$schema_name' FOR XML PATH('') ), 2, 9999),'elim'; SELECT zt2.*, 0 as elim FROM [zeust1].[$schema_name].[$table_name] zt1 right join [zeust2].[$schema_name].[$table_name] zt2 on "
    
    estado=1
    while IFS="," read -r column data_type pkflag
    do
        #registros nuevos
        join="zt1.$column = zt2.$column"
        primarykey=$column
        query="$query $join where zt1.$column is null UNION ALL"
        #registros actualizados
        query="$query SELECT zt2.*, 0 as elim FROM [zeust1].[$schema_name].[$table_name] zt1 join [zeust2].[$schema_name].[$table_name] zt2 on (zt1.$primarykey = zt2.$primarykey) and ("
        estado=2
        if [[ "$estado" == '2' ]]; then
            break
        fi
    done < /mnt/external/exports/columns.csv

    #joins de registros actualizados
    while IFS="," read -r column data_type
    do
        query="$query zt1.$column != zt2.$column or"
    done < /mnt/external/exports/columns.csv
    query="${query%or}) UNION ALL"

    #registros eliminados
    query="$query SELECT zt1.*, 1 as elim FROM [zeust1].[$schema_name].[$table_name] zt1 left join [zeust2].[$schema_name].[$table_name] zt2 on"
    query="$query $join where zt2.$primarykey is null"
    echo $query

    /opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -s, -h -1 -m 1 -W -Q "$query" > /mnt/external/exports/$table.csv
done