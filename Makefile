# -*- makefile-gmake -*-

all:
dist:
.PHONY: dist all install

dist_files= \
 cpulook/cpulook \
 cpulook/cpugetdata.sh \
 cpulook/cpuseekd \
 cpulook/cpusub \
 cpulook/m \
 cpulook/cpugethost.sh \
 cpulook/cpulast \
 cpulook/cpups \
 cpulook/cputop \
 cpulook/cpulist.cfg \
 cpulook/readme.txt

distexclude= \
	--exclude=./cpulook/tmp \
	--exclude=./cpulook/log \
	--exclude=./cpulook/*~ \
	--exclude=./cpulook/*.edit \
	--exclude=./cpulook/backup \
	--exclude=./cpulook/*/backup \
	--exclude=./cpulook/task.* \
	--exclude=./cpulook/*.log \
	--exclude=./cpulook/cpulist.cfg

dist: ext/echox
#	cd .. && tar cavf cpulook.tar.xz $(dist_files)
	cd .. && tar cavf cpulook-$$(date +%Y%m%d).tar.xz ./cpulook $(distexclude)

ext/echox: $(MWGDIR)/echox
	cp -p $< $@

install:
	./install.sh
