# -*- makefile-gmake -*-

all:
dist:
.PHONY: dist all install

distexclude= \
	--exclude=./cpulook/tmp \
	--exclude=./cpulook/log \
	--exclude=./cpulook/*~ \
	--exclude=./cpulook/*.edit \
	--exclude=./cpulook/backup \
	--exclude=./cpulook/*/backup \
	--exclude=./cpulook/task.* \
	--exclude=./cpulook/*.log \
	--exclude=./cpulook/cpulist.cfg \
	--exclude=./cpulook/.git

dist: ext/echox
	cd .. && tar cavf cpulook-$$(date +%Y%m%d).tar.xz ./cpulook $(distexclude)

ext/echox: $(MWGDIR)/echox
	cp -p $< $@

install:
	./install.sh
