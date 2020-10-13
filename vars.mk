APACHE_JENA_FUSEKI_REPO := daschswiss/apache-jena-fuseki

ifeq ($(BUILD_TAG),)
	BUILD_TAG := $(shell git describe --tag --abbrev=0)
endif
ifeq ($(BUILD_TAG),)
	BUILD_TAG := $(shell git rev-parse --verify HEAD)
endif

ifeq ($(APACHE_JENA_FUSEKI_IMAGE),)
	APACHE_JENA_FUSEKI_IMAGE := $(APACHE_JENA_FUSEKI_REPO):$(BUILD_TAG)
endif
