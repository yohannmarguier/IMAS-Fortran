all: compile link

compile:
	gfortran `pkg-config --cflags al-fortran` -c -o example_001_open_database.o example_001_open_database.f90
	gfortran -c -o example_001_main.o example_001_main.f90

link:
	gfortran `pkg-config --libs al-fortran al-core` -o main example_001_main.o example_001_open_database.o

