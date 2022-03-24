mkdir /mnt/external/exports

/opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -s. -h -1 -m 1 -W -Q "SET NOCOUNT ON; USE zeust1; SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES" > /mnt/external/exports/tables.txt


for table in $(cat /mnt/external/exports/tables.txt); do
    schema_name="${table%.*}"
    table_name="${table#*.}"

    columns_query="SET NOCOUNT ON; USE zeust1; SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='$table_name' AND TABLE_SCHEMA='$schema_name'"
    /opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -s, -h -1 -m 1 -W -Q "$columns_query" > /mnt/external/exports/columns.csv
        
    query="SET NOCOUNT ON; USE zeust1; SELECT SUBSTRING((SELECT ','+ COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='$table_name' AND TABLE_SCHEMA='$schema_name' FOR XML PATH('') ), 2, 9999); SELECT "
    while IFS="," read -r column data_type
    do
        if [ "$data_type" = "varchar" ]; then
            query="$query ('\"' + $column + '\"') as $column,"
        else
            query="$query $column,"
        fi
    done < /mnt/external/exports/columns.csv
    query="${query%,} FROM $schema_name.$table_name"
    echo $query

    /opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -s, -m 1 -y 0 -Q "$query" > /mnt/external/exports/$table.csv
done