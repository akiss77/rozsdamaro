# Rozsdamaro -- Rules for building its own README.md documentation
#
# Copyright (c) 2015, University of Szeged
# Copyright (c) 2015, Akos Kiss <akiss@inf.u-szeged.hu>


################################################################################
## ## Self-documentation rules
##
## * make doc
##

README.md: Makefile $(wildcard mk/*.mk)
	cat $^ | grep "^\(## \|##\$$\)" | cut -c 4- >$@

.PHONY: doc
doc: README.md
