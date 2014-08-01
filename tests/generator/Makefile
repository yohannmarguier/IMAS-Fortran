TARGETS= comparator helper testSuite

F90_gfortran=gfortran
COPTS_gfortran = -g -fdefault-real-8 -fPIC -fno-second-underscore -ffree-line-length-none -I$(UAL)/fortraninterface/amd64_gfortran
LIBS_gfortran=-L$(UAL)/fortraninterface -lUALFORTRANInterface_gfortran -Wl,-rpath,$(UAL)/itmcatalog/lib -L$(UAL)/lowlevel -lUALLowLevel -lm

CPODEF= $(UAL)/xml/IDSDef.xml

all : setup
	
clean:
	rm -rf build *~ *.o *.mod
	
clean-src: clean
	rm -f *.o

install: all
	
setup: IDSDef2TestSuite.xsl  
	xsltproc IDSDef2TestSuite.xsl $(CPODEF)  > testSuite.f90




comp: $(TARGETS)


#--------------------- gfortran ------------------------

helper: helper.f90
	$(F90_gfortran) $(COPTS_gfortran)   -c $^

comparator: comparator.f90
	$(F90_gfortran) $(COPTS_gfortran)   -c $^ 

testSuite: testSuite.f90 helper.o comparator.o
	$(F90_gfortran) $(COPTS_gfortran)   -o $@ $^ $(LIBS_gfortran)


	

