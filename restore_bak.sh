#crear bds
#/opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -i "/createDW.sql"

#preparar las bd's
/opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -d master -i "/create_procedure_restoreheaderonly.sql"
/opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -d master -i "/create_procedure_restoredatabase_dinamic.sql"


#restuarar bd's
for f in /mnt/external/*.bak;
do
    s=${f##*/}
    name="${s%.*}"
    extension="${s#*.}"

    #restuarar primera
    echo "Restoring $f..."
    /opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -d master -Q "EXEC dbo.restoredatabase '/mnt/external/$name.$extension', '1', 'zeust1'"

    #restaurar segunda
    echo "Restoring $f..."
    /opt/mssql-tools/bin/sqlcmd -l 300 -S localhost -U sa -P $SA_PASSWORD -d master -Q "EXEC dbo.restoredatabase '/mnt/external/$name.$extension', '2', 'zeust2'"

done