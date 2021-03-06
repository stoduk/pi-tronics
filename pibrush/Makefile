# Makefile for PiBrush 
# This code is copyright Hamish Cunningham and the University of Sheffield
# and is licenced under GPL 3 or any later version.

# vars #######################################################################
VERSION=1.0
P=pibrush
D=pibrushd
PD=package/$(VERSION)
INSTALLED_FILES=\
  $(DESTDIR)/usr/bin/$(P) \
  $(DESTDIR)/etc/init.d/$(P) \
  $(DESTDIR)/etc/default/$(P) \
  $(DESTDIR)/usr/share/man/man8/$(P).8.gz \
  $(DESTDIR)/opt/pibrush/accel_client.py \
  $(DESTDIR)/opt/pibrush/accel_server.py \
  $(DESTDIR)/opt/pibrush/examples.zip
INIT_LINKS=\
  $(DESTDIR)/etc/rc?.d/*$(P)
PACKAGE_FILES=\
  $(P)_$(VERSION)*.deb \
  $(P)_$(VERSION)*.dsc \
  $(P)_$(VERSION)*.tar.gz \
  $(P)_$(VERSION)*.changes \
  $(P)_$(VERSION)*.build
NOW:=$(shell date "+%Y-%m-%d-%R" |sed 's,:,,')
MAJOR_VERSION:=$(shell echo $(VERSION) |sed 's,\([0-9]*\)\..*,\1,')
MINOR_VERSION:=$(shell echo $(VERSION) |sed 's,.*\.,,')
SNAPSHOT_VERSION:=$(VERSION)+$(shell expr $(MINOR_VERSION) + 1)
SNAPSHOT:=$(SNAPSHOT_VERSION)-SNAPSHOT-$(NOW)
SNAPD:=$(PD)/snapshots/$(SNAPSHOT)

# functions ##################################################################
do-listing=\
  ls $(INSTALLED_FILES) `[ -z "$(DESTDIR)" ] && echo $(INIT_LINKS)` || :

# help #######################################################################
help:
	@echo 'Makefile for PiBrush                                        '
	@echo '                                                              '
	@echo 'Usage:                                                        '
	@echo '   make install                   installs the PiBrush daemon'
	@echo '   make uninstall                 removes the daemon          '
	@echo '   make list                      list installed files        '
	@echo '   make package                   create .deb/.dcs packagings '
	@echo '   make package-upload            upload to PPA repository    '
	@echo '   make package-clean             delete tmp packaging files  '
	@echo '   make package-info              apt-cache showpkg           '
	@echo '   make package-purge             apt-get purge               '
	@echo '   make package-version           update the changelog        '
	@echo '                                                              '

# install ####################################################################
# (if DESTDIR is set we assume this is a packaging run, not an install, and so
# don't run update-rc.d)
install:
	install -d -m 755         $(DESTDIR)/usr/bin
	install -d -m 755         $(DESTDIR)/etc/init.d
	install -d -m 755         $(DESTDIR)/etc/default
	install -d -m 755         $(DESTDIR)/usr/share/man/man8
	install -d -m 755         $(DESTDIR)/opt/pibrush
	install $(D).default      $(DESTDIR)/etc/default/$(D)
	install -m 755 $(P)       $(DESTDIR)/usr/bin
	install -m 755 $(D).init  $(DESTDIR)/etc/init.d/$(D)
	install man/$(P).8.gz     $(DESTDIR)/usr/share/man/man8
	install -m 755 bin/accel_client.py      $(DESTDIR)/opt/pibrush
	install -m 755 bin/accel_server.py      $(DESTDIR)/opt/pibrush
	install -m 644 bin/examples.zip         $(DESTDIR)/opt/pibrush
	[ -z "$(DESTDIR)" ] && update-rc.d $(D) defaults || :
	@echo 'PiBrush installed: '
	@$(do-listing)

# uninstall ##################################################################
uninstall:
	@echo 'removing PiBrush files: '
	@$(do-listing)
	[ -z "$(DESTDIR)" ] && update-rc.d -f $(D) remove || :
	sudo rm -f $(INSTALLED_FILES)
	@echo done

# manpage ####################################################################
man: man/$(P).txt
	cd man; ../utils/txt2man -v "System Manager's Manual" -s 8 \
          -t '$(P)' $(P).txt >$(P).8; \
	sed -i 1d $(P).8;  # fix error from lintian about ." macro \
	cat $(P).8 | gzip >$(P).8.gz

# package ####################################################################
package: man package-unstable package-precise
	@echo "\nunstable:"
	@ls -lh $(PD)/unstable
	@echo "\nprecise:"
	@ls -lh $(PD)/precise
package-unstable:
	@echo 'packaging PiBrush for Debian unstable...'
	mkdir -p $(PD)/unstable
	rm -f $(PD)/unstable/*
	sed -i \
          's,\(^$(P) ('$(VERSION)') \)[a-z]*,\1unstable,' debian/changelog
	debuild -Ipackage
	@echo ""
	cd .. && for f in $(PACKAGE_FILES); do \
          [ -f $$f ] && mv $$f $(P)/$(PD)/unstable || :; done
package-precise:
	@echo 'packaging PiBrush for Ubuntu precise...'
	mkdir -p $(PD)/precise
	rm -f $(PD)/precise/*
	sed -i 's,\(^$(P) ('$(VERSION)') \)[a-z]*,\1precise,' debian/changelog
	debuild -S -Ipackage
	sed -i 's,\(^$(P) ('$(VERSION)') \)[a-z]*,\1unstable,' \
          debian/changelog
	@echo ""
	cd .. && for f in $(PACKAGE_FILES); do \
          [ -f $$f ] && mv $$f $(P)/$(PD)/precise || :; done
snapshot:
	@echo "packaging PiBrush SNAPSHOT $(SNAPSHOT)..."
	mkdir -p $(SNAPD)
	rm -rf $(SNAPD)/*
	sed -i -e 's,\(^$(P) ('$(VERSION)') \)[a-z]*,\1precise,' \
	       -e 's,^$(P) ($(VERSION),$(P) ($(SNAPSHOT_VERSION),' \
          debian/changelog
	@head -1 debian/changelog
	debuild -S -Ipackage
	sed -i -e 's,^$(P) ($(SNAPSHOT_VERSION),$(P) ($(VERSION),' \
               -e 's,\(^$(P) ('$(VERSION)') \)[a-z]*,\1unstable,' \
          debian/changelog
	@head -1 debian/changelog
	@echo ""
	cd .. && for f in $(PACKAGE_FILES); do \
          [ -f $$f ] && mv $$f $(P)/$(SNAPD) || :; done
	@echo "\nsnapshot:"
	@ls -lhR $(SNAPD)

# package-upload #############################################################
package-upload:
	cd $(PD)/precise && dput ppa:hamish-dcs/pi-gate \
          $(P)_$(VERSION)_source.changes
	cd $(PD)/precise && mv $(P)_$(VERSION)*.ppa.upload /tmp || :

# snapshot-upload ############################################################
# relies on lexical ordering of snapshot names to pick the latest one
# (apt also relies on this ordering)
snapshot-upload:
	cd package/$(VERSION)/snapshots; \
	LAST_SNAP=`ls -r |head -1`; \
        cd $$LAST_SNAP && \
          dput ppa:hamish-dcs/pi-gate-snapshots $(P)*_source.changes; \
	mv $(P)_*.ppa.upload /tmp || :

# package utilities
package-info:
	apt-cache showpkg $(P)
package-purge:
	apt-get purge $(P)
package-clean:
	dh_clean
package-version:
	dch -i
	@echo 'remember to change VERSION in the Makefile!'

# list #######################################################################
list:
	@$(do-listing)

# phonies ####################################################################
.PHONY: install uninstall package package-unstable package-precise
.PHONY: package-upload package-clean list man
