IDSDEF	= ../xml/IDSDef.xml

all: IDSDef2F90Makefile.xsl
	xsltproc IDSDef2F90Makefile.xsl $(IDSDEF)
	$(MAKE) -f makefile-gen ids_schemas.f90
	$(MAKE) -f makefile-gen ids_routines.f90
	$(MAKE) -f makefile-gen

install:
	$(MAKE) -f makefile-gen install

clean: 
	$(MAKE) -f makefile-gen clean

clean-src:
	$(MAKE) -f makefile-gen clean-src
	rm -f makefile-gen
	
	
test: 
	(cd ./tests/generator/; $(MAKE)  test)

test-clean: 
	(cd ./tests/generator/; $(MAKE)  clean)

test-clean-src:
	(cd ./tests/generator/; $(MAKE)  clean-src)


