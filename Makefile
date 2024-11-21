GCC = gcc217 -g
#GCC = gcc217m

all: mywcc mywcs fibc fibs fibopt

clean:
	rm -f $(TARGETS) meminfo*.out

clobber: clean
	rm -f mywcs.o mywcc.o fibc fibs fibopt *.o *~

fibc: fib.o bigint.o bigintadd.o
	$(GCC) fib.o bigint.o bigintadd.o -o fibc

fibs: fib.o bigint.o bigintadds.o
	$(GCC) fib.o bigint.o bigintadds.o -o fibs

fibopt: fib.o bigint.o bigintaddopt.o
	$(GCC) fib.o bigint.o bigintaddopt.o -o fibopt

fib.o: fib.c
	$(GCC) -c fib.c -o fib.o

simple.o: simple.c bigint.h
	$(GCC) -c simple.c -o simple.o

bigint.o: bigint.c bigint.h
	$(GCC) -c bigint.c -o bigint.o

bigintadd.o: bigintadd.c
	$(GCC) -c bigintadd.c -o bigintadd.o

bigintadds.o: bigintadd.s
	$(GCC) -c bigintadd.s -o bigintadds.o

bigintaddopt.o: bigintaddopt.s
	$(GCC) -c bigintaddopt.s -o bigintaddopt.o

mywcc: mywcc.o
	$(GCC) mywcc.o -o mywcc

mywcs: mywcs.o
	$(GCC) mywcs.o -o mywcs

mywcc.o: mywc.c
	$(GCC) -c mywc.c -o mywcc.o

mywcs.o: mywc.s
	$(GCC) -c mywc.s -o mywcs.o


# 2a. gcc217 -o fib fib.c bigint.c bigintadd.c
# 2b. gcc217 -o fib fib.c bigint.c bigintadd.c -D NDEBUG -O
# 2c. gcc217 -o fib fib.c bigint.c bigintadd.c -D NDEBUG -O -pg
#		gprof fib > performance
# 2d. gcc217 -o fib fib.c bigint.c flatbigintadd.c
# 2e. gcc217 -o fibopt fib.c bigint.c bigintaddopt.s -D NDEBUG -O -pg

