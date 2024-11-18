GCC = gcc217 -g
#GCC = gcc217m

all: mywcc mywcs

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