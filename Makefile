include ../Makefile.common

IDSDEF	= ../xml/IDSDef.xml

all: makefile-gen pkgconfig
	$(MAKE) -f makefile-gen ids_schemas.f90
	$(MAKE) -f makefile-gen ids_routines.f90
	$(MAKE) -f makefile-gen

makefile-gen: IDSDef2F90Makefile.xsl
	xsltproc IDSDef2F90Makefile.xsl $(IDSDEF)

install: makefile-gen pkgconfig_install
	$(MAKE) -f makefile-gen install

clean: makefile-gen
	$(MAKE) -f makefile-gen clean

clean-src: makefile-gen
	$(MAKE) -f makefile-gen clean-src
	rm -f makefile-gen

test:
	$(MAKE) -C tests/generator test

test-clean:
	$(MAKE) -C tests/generator clean

test-clean-src:
	$(MAKE) -C tests/generator clean-src

PC_FILES = imas-ifort.pc imas-gfortran.pc imas-pgi.pc imas-g95.pc

include ../Makefile.pkgconfig
