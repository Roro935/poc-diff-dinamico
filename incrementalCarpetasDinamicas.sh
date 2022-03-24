#modificar datos
#/opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -i "/modify_real_data.sql"

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

    date_format=$(date +'%Y%m%d')

    year=$(date +'%Y')

    mkdir /mnt/external/exports/raw/$year/$table_name

    columns_query_pk="SET NOCOUNT ON; USE zeust1; WITH COLUMN_DATA AS (SELECT COLUMN_NAME, DATA_TYPE, TABLE_NAME, TABLE_SCHEMA
                            FROM INFORMATION_SCHEMA.COLUMNS 
                            WHERE TABLE_NAME='$table_name' AND TABLE_SCHEMA='$schema_name'),
                            PK_INDICATOR AS (SELECT COLUMN_NAME, 1 as PKflag,  TABLE_NAME, TABLE_SCHEMA
                            FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
                            WHERE OBJECTPROPERTY(OBJECT_ID(CONSTRAINT_SCHEMA + '.' + QUOTENAME(CONSTRAINT_NAME)), 'IsPrimaryKey') = 1
                            AND TABLE_NAME = '$table_name' AND TABLE_SCHEMA = '$schema_name'), T_PREVIA AS(
                            SELECT COLUMN_DATA.COLUMN_NAME, COLUMN_DATA.DATA_TYPE,
                                CASE WHEN COLUMN_DATA.COLUMN_NAME = PK_INDICATOR.COLUMN_NAME THEN PK_INDICATOR.PKflag
                                ELSE 0
                                END AS PKflag
                            FROM COLUMN_DATA 
                            JOIN PK_INDICATOR on PK_INDICATOR.TABLE_NAME = COLUMN_DATA.TABLE_NAME 
                            AND PK_INDICATOR.TABLE_SCHEMA = COLUMN_DATA.TABLE_SCHEMA)
                            SELECT * FROM T_PREVIA 
                            WHERE T_PREVIA.PKflag=1"
    /opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -s, -h -1 -m 1 -W -Q "$columns_query_pk" > /mnt/external/exports/pk_columns.csv

    columns_query="SET NOCOUNT ON; USE zeust1; WITH COLUMN_DATA AS (SELECT COLUMN_NAME, DATA_TYPE, TABLE_NAME, TABLE_SCHEMA
                            FROM INFORMATION_SCHEMA.COLUMNS 
                            WHERE TABLE_NAME='$table_name' AND TABLE_SCHEMA='$schema_name'),
                            PK_INDICATOR AS (SELECT COLUMN_NAME, 1 as PKflag,  TABLE_NAME, TABLE_SCHEMA
                            FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
                            WHERE OBJECTPROPERTY(OBJECT_ID(CONSTRAINT_SCHEMA + '.' + QUOTENAME(CONSTRAINT_NAME)), 'IsPrimaryKey') = 1
                            AND TABLE_NAME = '$table_name' AND TABLE_SCHEMA = '$schema_name'), T_PREVIA AS(
                            SELECT COLUMN_DATA.COLUMN_NAME, COLUMN_DATA.DATA_TYPE,
                                CASE WHEN COLUMN_DATA.COLUMN_NAME = PK_INDICATOR.COLUMN_NAME THEN PK_INDICATOR.PKflag
                                ELSE 0
                                END AS PKflag
                            FROM COLUMN_DATA
							left JOIN PK_INDICATOR on PK_INDICATOR.COLUMN_NAME = COLUMN_DATA.COLUMN_NAME
							where PK_INDICATOR.COLUMN_NAME is null)
                            SELECT * FROM T_PREVIA
                            WHERE T_PREVIA.PKflag=0"
    /opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -s, -h -1 -m 1 -W -Q "$columns_query" > /mnt/external/exports/no_pk_columns.csv

    query="SET NOCOUNT ON; USE zeust1 ; SELECT SUBSTRING((SELECT ','+ COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='$table_name' AND TABLE_SCHEMA='$schema_name' FOR XML PATH('') ), 2, 9999),'elim'; SELECT zt2.*, 0 as elim FROM [zeust1].[$schema_name].[$table_name] zt1 right join [zeust2].[$schema_name].[$table_name] zt2 on "
    
    join=""
    while IFS="," read -r column data_type pkflag
    do
        #registros nuevos
        #join="zt1.$column = zt2.$column"
        primarykey=$column
        join="$join zt1.$column = zt2.$column and"
        #query="$query $join where zt1.$column is null UNION ALL"
                
    done < /mnt/external/exports/pk_columns.csv
    join="${join%and} "
    query="$query $join where zt1.$primarykey is null UNION ALL"

    #registros actualizados
    query="$query SELECT zt2.*, 0 as elim FROM [zeust1].[$schema_name].[$table_name] zt1 join [zeust2].[$schema_name].[$table_name] zt2 on ($join)"

    #joins de registros actualizados
    query="$query and ("
    while IFS="," read -r column data_type
    do
        query="$query zt1.$column != zt2.$column or"
    done < /mnt/external/exports/no_pk_columns.csv
    query="${query%or}) UNION ALL"

    #registros eliminados
    query="$query SELECT zt1.*, 1 as elim FROM [zeust1].[$schema_name].[$table_name] zt1 left join [zeust2].[$schema_name].[$table_name] zt2 on"
    query="$query $join where zt2.$primarykey is null"
    echo $table
    echo $query

    /opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -s, -m 1 -y 0 -Q "$query" > /mnt/external/exports/raw/$year/$table_name/$date_format.csv
done