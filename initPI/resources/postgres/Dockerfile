FROM postgres:14.1


RUN apt-get update && apt-get install -y postgresql-14-postgis-3 && apt-get install -y postgresql-14-ogr-fdw


CMD ["/usr/local/bin/docker-entrypoint.sh","postgres"]
