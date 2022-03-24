# loop until SQL is ready

for i in {1..60};
do
    /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD  -Q "SELECT Name FROM SYS.DATABASES"
    if [ $? -eq 0 ]
    then
        echo "sql server ready"
        break
    else
        echo "not ready yet..."
        sleep 1
    fi
done

/opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -d master -i "/create_procedure_restoreheaderonly.sql"
/opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -d master -i "/create_procedure_restoredatabase.sql"
#run the setup script to create the DB and the schema in the DB
#do this in a loop because the timing for when the SQL instance is ready is indeterminate
for f in /mnt/external/*.bak;
do
    s=${f##*/}
    name="${s%.*}"
    extension="${s#*.}"

    echo "Restoring $f..."
    /opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -d master -q "EXEC dbo.restoredatabase '/mnt/external/$name.$extension', '$name'"

    echo "Creating csv files..."
    mkdir /mnt/external/exports
    
    /opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -d $name -s. -h -1 -W -Q "SET NOCOUNT ON; SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES" > /mnt/external/exports/tables.txt

    for table in $(cat /mnt/external/exports/tables.txt); do
        schema_name="${table%.*}"
        table_name="${table#*.}"

        columns_query="SET NOCOUNT ON; SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='$table_name' AND TABLE_SCHEMA='$schema_name'"
        /opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -d $name -s, -h -1 -W -Q "$columns_query" > /mnt/external/exports/columns.csv
        
        query="SET NOCOUNT ON; SELECT SUBSTRING((SELECT ','+ COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='$table_name' AND TABLE_SCHEMA='$schema_name' FOR XML PATH('') ), 2, 9999); SELECT "
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

        /opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -d $name -s, -h -1 -W -Q "$query" > /mnt/external/exports/$table.csv
    done
done

#az storage fs file upload \
#    -s /mnt/c/Users/MARCELOJOSEINOCENTEC/Documents/Qroma/dashboard/20211011.csv \
#    -p enrollment/raw/2021/20211011.csv \
#    -f datalakezeusfs \
#    --account-name datalakezeus \
#    --auth-mode login
