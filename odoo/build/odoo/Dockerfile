ARG ODOO_VERSION
FROM odoo:${ODOO_VERSION}

# Install packages from requirements.txt
USER root

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive \
	apt-get update \
	&& apt-get install -y --no-install-recommends \
	dos2unix \
	default-jdk \
	build-essential libssl-dev libffi-dev python3-dev \
	swig \
	&& apt-get -y clean

COPY ./requirements.txt /etc/odoo/requirements.txt

# Install packages
RUN python3 -m pip install --upgrade pip \
	&& python3 -m pip install wheel \
	&& python3 -m pip install -r /etc/odoo/requirements.txt \
	&& python3 -m pip cache purge

COPY ./modules /mnt/extra-addons
COPY ./config/odoo.conf /etc/odoo/odoo.conf

# Ensure correct file endings, update config, update relevant directories' permissions
RUN find /mnt/extra-addons -type f -print0 | xargs -0 dos2unix -q -s -S -- \
	MODULE_PATHS=''; \
	for MODULE_PATH in $(find . -name '__manifest__.py' | rev | cut -d '/' -f 3- | rev | uniq | xargs readlink -f); \
	do MODULE_PATHS="${MODULE_PATH},${MODULE_PATHS}"; \
	done \
	&& MODULE_PATHS="${MODULE_PATHS/%,/}" \
	&& sed -i "s#[; ]*addons_path =.*#addons_path = ${MODULE_PATHS}#g" /etc/odoo/odoo.conf \
	&& chown -R odoo /var/lib/odoo /mnt /etc/odoo \
	&& chmod -R 750 /var/lib/odoo /mnt /etc/odoo

USER odoo
