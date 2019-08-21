CC=gcc
FLAGS=-Wall -O0

all: faxpy.out

faxpy.out: test_faxpy.o faxpy.o
	$(CC) $(FLAGS) $^ -o $@
test_faxpy.o: test_faxpy.c
	$(CC) $(FLAGS) -c $< -o $@
faxpy.o: faxpy.s
	$(CC) $(FLAGS) -c $< -o $@

clean: 
	rm -r -f *.o *.out
