SHELL=/bin/sh

export BUILDKIT_PROGRESS=tty
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1
export GROUP_ID=$(shell id -u)
export USER_ID=$(shell id -u)


build:
	docker build \
		--build-arg GROUP_ID=$$GROUP_ID \
		--build-arg USER_ID=$$USER_ID \
		-t msssql-incremental .

run:
	docker build \
		--build-arg GROUP_ID=$$GROUP_ID \
		--build-arg USER_ID=$$USER_ID \
		-t msssql-incremental .
	docker run --rm --privileged -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=Server2016' \
		-p 1433:1433 \
		-v "$(CURDIR)":/mnt/external \
		--name incremental msssql-incremental

upload:
	az storage blob upload --account-name storagezeus \
		--account-key wiixACo/VgsrCGzVB53qgQrwTDSPE38DPgCKf6ytxDo06PNSAwQkcRTEm/xMhiOXveWWgGRddjoJ/SVPxCD6Yw== \
		--file BackFranquiciasDW16112020.bacpac \
		--container-name backups \
		--name BackFranquiciasDW16112020.bacpac

	az sql db import --resource-group QromaCloud \
		--server zeustest -u cppqzeus -p Z3ust3st --name Consolidado_Zeus_FRQ \
		--storage-key-type StorageAccessKey --storage-key wiixACo/VgsrCGzVB53qgQrwTDSPE38DPgCKf6ytxDo06PNSAwQkcRTEm/xMhiOXveWWgGRddjoJ/SVPxCD6Yw== \
		--storage-uri https://storagezeus.blob.core.windows.net/backups/BackFranquiciasDW16112020.bacpac

#docker run --privileged -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=Winter2019' -p 1433:1433 --name=MSSQL -d mcr.microsoft.com/mssql/server:2019-latest
#docker exec -it bak-to-bacpac /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Winter2019

docker-install-pre:
	sudo apt remove containerd docker docker-engine docker.io runc -y || true
	sudo apt update -y
	sudo apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common -y
	sudo passwd $(USER)

docker-install:
	make docker-install-pre
	$(eval export DISTRIBUTOR_ID=$(shell lsb_release -si))
	$(eval export DISTRIBUTOR_ID=$(shell echo $(DISTRIBUTOR_ID) | awk '{print tolower($$0)}'))
	curl -fsSL https://download.docker.com/linux/$$DISTRIBUTOR_ID/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$$DISTRIBUTOR_ID $$(lsb_release -cs) stable"
	sudo apt update -y
	sudo apt install containerd.io docker-ce docker-ce-cli -y
	sudo usermod -aG docker $(USER)
	su - $(USER)
