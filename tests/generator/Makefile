TARGETS=  ifort_testSuite


#------------------------------- gfortran ----------------------------------
F90_gfortran      = gfortran
COPTS_gfortran    = -g -fdefault-real-8 -fPIC -fno-second-underscore -ffree-line-length-none
INCDIR_gfortran   = -I$(UAL)/fortraninterface/amd64_gfortran
#LIBS_gfortran    = -L$(UAL)/fortraninterface -lUALFORTRANInterface_gfortran -Wl,-rpath,$(UAL)/itmcatalog/lib -L$(UAL)/lowlevel -lUALLowLevel -lm
LIBS_gfortran     = -L$(UAL)/fortraninterface -lUALFORTRANInterface_gfortran 

F90_ifort       = ifort
COPTS_ifort     = -r8 -O0 -assume no2underscore  -fPIC -module $(UAL)/fortraninterface/amd64_ifort -shared-intel
INCDIR_ifort    = -I$(UAL)/fortraninterface/amd64_ifort
LIBS_ifort      = -L$(UAL)/fortraninterface -lUALFORTRANInterface_ifort 

IDSDEF= $(UAL)/xml/IDSDef.xml


ifeq "$(strip $(G95))" "yes"
    TARGETS += libUALFORTRANInterface_g95.so libUALFORTRANInterface_g95.a 
endif

ifeq "$(strip $(GFORTRAN))" "yes"
    TARGETS += libUALFORTRANInterface_gfortran.so libUALFORTRANInterface_gfortran.a
endif

ifeq "$(strip $(PGI))" "yes"
    TARGETS += libUALFORTRANInterface_pgi.so libUALFORTRANInterface_pgi.a
endif

ifeq "$(strip $(IFORT))" "yes"
    TARGETS += libUALFORTRANInterface_ifort.so libUALFORTRANInterface_ifort.a 
endif

all : setup
	
clean:
	rm -rf build *~ *.o *.mod
	
clean-src: clean
	rm -f *.o

install: all
	
setup: IDSDef2TestSuite.xsl  
	xsltproc IDSDef2TestSuite.xsl $(IDSDEF)  > testSuite.f90




comp: $(TARGETS)


#--------------------- gfortran ------------------------

gfortran_helper.o: helper.f90
	$(F90_gfortran) $(COPTS_gfortran) $(INCDIR_gfortran) -c $< -o $@ 

gfortran_comparator.o: comparator.f90
	$(F90_gfortran) $(COPTS_gfortran) $(INCDIR_gfortran) -c $< -o $@ 

gfortran_testSuite: testSuite.f90 gfortran_helper.o gfortran_comparator.o
	$(F90_gfortran) $(COPTS_gfortran)  $(INCDIR_gfortran) -o $@ $^ $(LIBS_gfortran)


	

#--------------------- ifort ------------------------

ifort_helper.o: helper.f90
	$(F90_ifort) $(COPTS_ifort) $(INCDIR_ifort) -c $< -o $@ 

ifort_comparator.o: comparator.f90
	$(F90_ifort) $(COPTS_ifort) $(INCDIR_ifort) -c $< -o $@ 

ifort_testSuite: testSuite.f90 ifort_helper.o ifort_comparator.o
	$(F90_ifort) $(COPTS_ifort)  $(INCDIR_ifort) -o $@ $^ $(LIBS_ifort)
