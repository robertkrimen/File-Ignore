.PHONY: all test time clean distclean dist distcheck upload distupload

all: test

install dist distclean test tardist: Makefile
	make -f $< $@

Makefile: Makefile.PL
	perl $<

clean: distclean

reset: clean
	perl Makefile.PL
	make -f Makefile test
