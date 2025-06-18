
EXEFILE = dst
OBJECTS = main.o desat.o
CCFMT = -O0 -no-pie -fno-pie -m32
NASMFMT = -f elf32
CCOPT = -g
NASMOPT = -g -w+all

.c.o:
	cc $(CCFMT) $(CCOPT) -c $<

.s.o:
	nasm $(NASMFMT) $(NASMOPT) -l $*.lst $<

$(EXEFILE): $(OBJECTS)
	cc $(CCFMT) -g -o $@ $^
	
clean:
	rm *.o *.lst $(EXEFILE)