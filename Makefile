GCC = gcc217 -g
#GCC = gcc217m

all: mywcc mywcs fib

clean:
	rm -f $(TARGETS) meminfo*.out

clobber: clean
	rm -f mywcs.o mywcc.o *~

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

