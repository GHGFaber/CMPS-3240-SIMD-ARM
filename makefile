CC=gcc
FLAGS=-Wall -O0

all: faxpy.out faxpySIMD4.out faxpySIMD2.out

faxpySIMD4.out: faxpySIMD4.o test_faxpy.o
	gcc -Wall -O0 $^ -o $@
faxpySIMD4.o: faxpySIMD4.s
	gcc -Wall -O0 -c $< -o $@
faxpySIMD2.out: faxpySIMD2.o test_faxpy.o
	gcc -Wall -O0 $^ -o $@
faxpySIMD2.o: faxpySIMD2.s
	gcc -Wall -O0 -c $< -o $@
faxpy.out: test_faxpy.o faxpy.o
	$(CC) $(FLAGS) $^ -o $@
test_faxpy.o: test_faxpy.c 
	$(CC) $(FLAGS) -c $< -o $@
faxpy.o: faxpy.s
	$(CC) $(FLAGS) -c $< -o $@

clean: 
	rm -r -f *.o *.out
