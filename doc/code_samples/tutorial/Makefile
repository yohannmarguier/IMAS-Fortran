FFLAGS= -g -fPIC
INCLUDE=`pkg-config al-fortran --cflags`
LIBS=`pkg-config al-fortran --libs`

SRCS := $(wildcard *.f90)
OBJS := $(patsubst %.f90,%.o,$(SRCS))

all: $(OBJS)
	$(FC) $(LIBS) -o test_new_examples $^

%.o: %.f90
	$(FC) $(INCLUDE) -c $<

clean:
	rm -f *.o
	rm -f test_new_examples
