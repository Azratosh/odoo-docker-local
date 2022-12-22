# Makefile to manage a local Odoo development stack.

# # # Configuration

SHELL = /bin/bash
.DEFAULT_GOAL := help

MODULE_DIR = ./build/odoo/modules
LOCAL_MODULE_DIR = ${MODULE_DIR}/local
OCA_MODULE_DIR = ${MODULE_DIR}/oca
THIRD_PARTY_MODULE_DIR = ${MODULE_DIR}/third-party

include .env



# # # Basic Targets


.PHONY = help
#: Prints a help message.
help:
	@echo -e "Run 'make init' to generate or update all configuration \
	and environment files. You must then configure these files accordingly."
	@echo "You can list valid targets with 'make list'."


.PHONY: list
#: Lists all available targets.
list:
	@grep -B1 -E "^[a-zA-Z0-9_-]+:([^\=]|$$)" Makefile \
	| grep -v -- -- \
	| sed 'N;s/\n/###/' \
	| sed -n 's/^#: \(.*\)###\(.*\):.*/\2###\1/p' \
	| column -t  -s '###'


.PHONY = init
#: Initializes the stack.
init: environment


.PHONY = check-user
check-user:
	@[ $$(id -u) -ne 0 ] || (echo "Current user must not be root" && exit 1)


.PHONY = build-dirs
build-dirs:
	@mkdir -p ${MODULE_DIR}
	@mkdir -p ${LOCAL_MODULE_DIR}
	@mkdir -p ${OCA_MODULE_DIR}
	@mkdir -p ${THIRD_PARTY_MODULE_DIR}


# # # Fetching Modules


.PHONY = modules
#: Rsyncs or clones all module directories.
modules: modules-local modules-oca modules-third-party


.PHONY = modules-local
#: Copy local Odoo module directories using rsync.
modules-local: check-user build-dirs
	@[ $$(sudo id -u) -eq 0 ] || (echo "Must be able to sudo in order to sync modules reliably" && exit 1)
	@echo "Syncing local module directories"
	@for DIRECTORY in $$(echo "${LOCAL_MODULES}" | tr ':' '\n'); do \
	  sudo su -c "rsync --delete -a $${DIRECTORY} ${LOCAL_MODULE_DIR}"; \
	done;
	@echo "Done"


.PHONY = modules-oca
#: Clone and checkout OCA module directories.
modules-oca: check-user build-dirs
	@echo "Syncing OCA module repositories"
	@cd ${OCA_MODULE_DIR}; \
	for REPO in $$(echo "${OCA_MODULES}" | tr ',' '\n'); do \
	  if [ -d "$${REPO}" ]; then \
	    cd $${REPO} && git reset --hard && git checkout ${ODOO_VERSION} && git pull || echo "Failed to checkout/pull branch ${ODOO_VERSION} for $${REPO}"; cd ..; \
	  else \
	    git clone "https://github.com/OCA/$${REPO}" --branch ${ODOO_VERSION} && echo "Cloned $${REPO}"; \
	  fi; \
	done;
	@echo "Done"


.PHONY = modules-third-party
#: Clone and checkout third party module repositories.
modules-third-party: check-user build-dirs
	@echo "Syncing third party module repositories"
	@cd ${THIRD_PARTY_MODULE_DIR}; \
	for REPO in $$(echo "${THIRD_PARTY_MODULES}" | tr ' ' '\n'); do \
	  DIR_NAME=$$(echo "$${REPO}" | rev | cut -d '/' -f 1 | rev | cut -d '.' -f 1); \
	  if [ -d "$${DIR_NAME}" ]; then \
		cd $${DIR_NAME} \
		  && git reset --hard && git checkout ${ODOO_VERSION} && git pull \
		  || echo "Failed to checkout/pull branch ${ODOO_VERSION} for $${REPO}"; \
		cd ..; \
	  else \
	    git clone "$${REPO}" --branch ${ODOO_VERSION} && echo "Cloned $${REPO}"; \
	  fi; \
	done;
	@echo "Done"



# # # Removing Modules


.PHONY = clear-modules
#: Removes all modules and module directories from the image build directory.
clear-modules: clear-modules-local clear-modules-oca clear-modules-third-party


.PHONY = clear-modules-local
#: Removes all locally rsync'ed modules.
clear-modules-local: build-dirs
	@echo "Removing local modules from the image build directory"
	@cd ${LOCAL_MODULE_DIR}; \
	for FILE in $$(ls .); do \
	  rm -rf "$${FILE}" && echo "$${FILE} removed"; \
	done


.PHONY = clear-modules-oca
#: Removes all cloned OCA modules.
clear-modules-oca: build-dirs
	@echo "Removing OCA modules from the image build directory"
	@cd ${OCA_MODULE_DIR}; \
	for FILE in $$(ls .); do \
	  rm -rf "$${FILE}" && echo "$${FILE} removed"; \
	done


.PHONY = clear-modules-third-party
#: Removes all cloned third party modules.
clear-modules-third-party: build-dirs
	@echo "Removing third party modules from the image build directory"
	@cd ${THIRD_PARTY_MODULE_DIR}; \
	for FILE in $$(ls .); do \
	  rm -rf "$${FILE}" && echo "$${FILE} removed"; \
	done



# # # Building Postgres & Odoo


.PHONY = build
#: Builds all images.
build: build-odoo build-postgres


.PHONY = odoo
#: Builds the custom Odoo development container image.
build-odoo: environment ./build/odoo/Dockerfile ./build/odoo/requirements.txt
	@cd build/odoo && docker build --build-arg ODOO_VERSION=${ODOO_VERSION} --network host . -t odoo-local:${ODOO_VERSION} --force-rm


.PHONY = postgres
#: Builds the custom Postgres development container image.
build-postgres: environment ./build/postgres/Dockerfile ./build/postgres/init
	@cd build/postgres && docker build --build-arg POSTGRES_VERSION=${POSTGRES_VERSION} --network host . -t postgres-odoo-local:${POSTGRES_VERSION} --force-rm


.PHONY = pull
#: Pulls the latest Odoo and Postgres container images..
pull: pull-odoo pull-postgres


.PHONY = pull-odoo
#: Pulls the latest Odoo container image.
pull-odoo: environment ./build/odoo/Dockerfile ./build/odoo/requirements.txt
	@echo "Pulling latest version of odoo:${ODOO_VERSION} ..." \
	&& docker pull odoo:${ODOO_VERSION} \
	&& echo "Pull successful"


.PHONY = pull-postgres
#: Pulls the latest Postgres container image.
pull-postgres: environment ./build/postgres/Dockerfile ./build/odoo/requirements.txt
	@echo "Pulling latest version of postgres:${POSTGRES_VERSION} ..." \
	&& docker pull postgres:${POSTGRES_VERSION} \
	&& echo "Pull successful"



# # # Environment Setup & Updates
# The following rule ensures that the user is notified about changes to
# .env.template and .env. .env is created if it does not exist.

.PHONY = environment
#: Creates the .env file according to .env.template. Also checks for changes made to .env.template.
environment: .env

.env: .env.template
	@if [ -f .env ]; \
 	then \
 	  DIFF=$$(diff -u \
	    <(grep -v '^$\|^\s*\#' .env | sort -u -t '=' -k 1,1 | cut -d"=" -f 1) \
	    <(grep -v '^$\|^\s*\#' .env.template | sort -u -t '=' -k 1,1 | cut -d"=" -f 1) \
	  ); \
	  if [ -n "$${DIFF}" ]; \
	  then \
	    echo -e "Environment variable changes found:\n" \
	    && echo "$${DIFF}" | grep -v '^\s*\#\|^+++\|^---' \
	    && echo -e "\nPlease update your .env file."; \
	    exit 1; \
	  else \
	    touch .env; \
	  fi; \
 	else \
  		cp .env.template .env && echo "Created .env"; \
  	fi
