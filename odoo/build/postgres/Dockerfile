ARG POSTGRES_VERSION
FROM postgres:${POSTGRES_VERSION}

# Generates and sets locale to UTF-8, which is then used by PostgreSQL
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

ADD ./init /docker-entrypoint-initdb.d/

# Installs additional dependencies used for upgrading Odoo
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update \
    && apt-get install -y --no-install-recommends \
    python3 curl \
    && apt-get -y clean
