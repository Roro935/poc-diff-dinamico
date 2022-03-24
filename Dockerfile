#FROM mcr.microsoft.com/mssql/server:2019-CU10-ubuntu-20.04
FROM mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04

ARG GROUP_ID
ARG USER_ID

# Switch to root user for access to apt-get install
USER root

# Install curl
RUN apt-get -y update
RUN apt-get install -y curl gnupg unzip

#Add the mssql-tools repository
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | tee /etc/apt/sources.list.d/msprod.list

#Install mssql-tools
RUN apt-get -y update
RUN apt-get install -y mssql-tools unixodbc-dev

#Copy sqlpackage utility and other required file to root of container
COPY . /
RUN chmod 777 *.sql
RUN chown -R mssql:root *.sql

RUN unzip /sqlpackage-linux-x64-en-US-15.0.5084.2.zip -d /sqlpackage
RUN chmod 777 -R /sqlpackage

#Create mount point folders
RUN mkdir -p /mnt/external
RUN chown -R mssql:root /mnt

#Set permissions on script file
RUN chmod a+x create-csvs.sh

# Switch back to mssql user and run the entrypoint script
RUN chmod 777 *.sh
RUN usermod -u $USER_ID mssql
USER mssql
ENTRYPOINT /bin/bash entrypoint.sh