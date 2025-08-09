# -*- makefile-gmake -*-

all:
dist:
.PHONY: dist all install

cmd := make/cmd.bash

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

script-files := \
  cpugetdata.sh \
  cpugethost.sh \
  cpukill \
  cpulast \
  cpulook \
  cpups \
  cpuseekd \
  cpusub \
  cputop

$(script-files): make/common-header.bash
	$(cmd) update-common-header $@

all: $(script-files)

dist: lib/echox.bash
	cd .. && tar cavf cpulook-$$(date +%Y%m%d).tar.xz ./cpulook $(distexclude)

lib/echox.bash: $(MWGDIR)/echox
	cp -p $< $@

install:
	./install.sh
