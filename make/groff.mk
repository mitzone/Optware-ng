###########################################################
#
# groff
#
###########################################################
#
# GROFF_VERSION, GROFF_SITE and GROFF_SOURCE define
# the upstream location of the source code for the package.
# GROFF_DIR is the directory which is created when the source
# archive is unpacked.
# GROFF_UNZIP is the command used to unzip the source.
# It is usually "zcat" (for .gz) or "bzcat" (for .bz2)
#
# You should change all these variables to suit your package.
# Please make sure that you add a description, and that you
# list all your packages' dependencies, seperated by commas.
# 
# If you list yourself as MAINTAINER, please give a valid email
# address, and indicate your irc nick if it cannot be easily deduced
# from your name or email address.  If you leave MAINTAINER set to
# "NSLU2 Linux" other developers will feel free to edit.
#
GROFF_SITE=http://ftp.gnu.org/gnu/groff/old
GROFF_VERSION=1.19.2
GROFF_SOURCE=groff-$(GROFF_VERSION).tar.gz
GROFF_DIR=groff-$(GROFF_VERSION)
GROFF_UNZIP=zcat
GROFF_MAINTAINER=NSLU2 Linux <nslu2-linux@yahoogroups.com>
GROFF_DESCRIPTION=front-end for the groff document formatting system
GROFF_SECTION=util
GROFF_PRIORITY=optional
GROFF_DEPENDS=libstdc++
GROFF_CONFLICTS=

#
# GROFF_IPK_VERSION should be incremented when the ipk changes.
#
GROFF_IPK_VERSION=3

#
# GROFF_PATCHES should list any patches, in the the order in
# which they should be applied to the source code.
#
GROFF_PATCHES=$(GROFF_SOURCE_DIR)/groff.patch

#
# If the compilation of the package requires additional
# compilation or linking flags, then list them here.
#
GROFF_CPPFLAGS=
GROFF_LDFLAGS=

#
# GROFF_BUILD_DIR is the directory in which the build is done.
# GROFF_SOURCE_DIR is the directory which holds all the
# patches and ipkg control files.
# GROFF_IPK_DIR is the directory in which the ipk is built.
# GROFF_IPK is the name of the resulting ipk files.
#
# You should not change any of these variables.
#
GROFF_BUILD_DIR=$(BUILD_DIR)/groff
GROFF_SOURCE_DIR=$(SOURCE_DIR)/groff
GROFF_IPK_DIR=$(BUILD_DIR)/groff-$(GROFF_VERSION)-ipk
GROFF_IPK=$(BUILD_DIR)/groff_$(GROFF_VERSION)-$(GROFF_IPK_VERSION)_$(TARGET_ARCH).ipk

.PHONY: groff-source groff-unpack groff groff-stage groff-ipk groff-clean groff-dirclean groff-check

$(DL_DIR)/$(GROFF_SOURCE):
	$(WGET) -P $(DL_DIR) $(GROFF_SITE)/$(GROFF_SOURCE)

groff-source: $(DL_DIR)/$(GROFF_SOURCE) $(GROFF_PATCHES)
#
# This builds the IPK file.
#
# Binaries should be installed into $(GROFF_IPK_DIR)$(TARGET_PREFIX)/sbin or $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin
# (use the location in a well-known Linux distro as a guide for choosing sbin or bin).
# Libraries and include files should be installed into $(GROFF_IPK_DIR)$(TARGET_PREFIX)/{lib,include}
# Configuration files should be installed in $(GROFF_IPK_DIR)$(TARGET_PREFIX)/etc/groff/...
# Documentation files should be installed in $(GROFF_IPK_DIR)$(TARGET_PREFIX)/doc/groff/...
# Daemon startup scripts should be installed in $(GROFF_IPK_DIR)$(TARGET_PREFIX)/etc/init.d/S??groff
#
# You may need to patch your application to make it use these locations.
#
$(GROFF_BUILD_DIR)/.configured: $(DL_DIR)/$(GROFF_SOURCE) $(GROFF_PATCHES) make/groff.mk
	rm -rf $(BUILD_DIR)/$(GROFF_DIR) $(@D)
	$(GROFF_UNZIP) $(DL_DIR)/$(GROFF_SOURCE) | tar -C $(BUILD_DIR) -xvf -
	cat $(GROFF_PATCHES) | $(PATCH) -d $(BUILD_DIR)/$(GROFF_DIR) -p1
	mv $(BUILD_DIR)/$(GROFF_DIR) $(@D)
	(cd $(@D); \
		$(TARGET_CONFIGURE_OPTS) \
		CPPFLAGS="$(STAGING_CPPFLAGS) $(GROFF_CPPFLAGS)" \
		LDFLAGS="$(STAGING_LDFLAGS) $(GROFF_LDFLAGS)" \
		./configure \
		--build=$(GNU_HOST_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--target=$(GNU_TARGET_NAME) \
		--prefix=\$$\(DESTDIR\)$(TARGET_PREFIX) \
		--without-x \
		--disable-nls \
	)
	touch $@

groff-unpack: $(GROFF_BUILD_DIR)/.configured

$(GROFF_BUILD_DIR)/.built: $(GROFF_BUILD_DIR)/.configured
	rm -f $@
	$(MAKE) -C $(@D) src/include
	$(MAKE) -C $(@D) src/libs/libgroff
	$(MAKE) -C $(@D) arch/misc
	$(MAKE) -C $(@D)
	touch $@

groff: $(GROFF_BUILD_DIR)/.built

#
# This rule creates a control file for ipkg.  It is no longer
# necessary to create a seperate control file under sources/groff
#
$(GROFF_IPK_DIR)/CONTROL/control:
	@$(INSTALL) -d $(@D)
	@rm -f $@
	@echo "Package: groff" >>$@
	@echo "Architecture: $(TARGET_ARCH)" >>$@
	@echo "Priority: $(GROFF_PRIORITY)" >>$@
	@echo "Section: $(GROFF_SECTION)" >>$@
	@echo "Version: $(GROFF_VERSION)-$(GROFF_IPK_VERSION)" >>$@
	@echo "Maintainer: $(GROFF_MAINTAINER)" >>$@
	@echo "Source: $(GROFF_SITE)/$(GROFF_SOURCE)" >>$@
	@echo "Description: $(GROFF_DESCRIPTION)" >>$@
	@echo "Depends: $(GROFF_DEPENDS)" >>$@
	@echo "Conflicts: $(GROFF_CONFLICTS)" >>$@

$(GROFF_IPK): $(GROFF_BUILD_DIR)/.built
	rm -rf $(GROFF_IPK_DIR) $(BUILD_DIR)/groff_*_$(TARGET_ARCH).ipk
	$(INSTALL) -d $(GROFF_IPK_DIR)$(TARGET_PREFIX)
	$(INSTALL) -d $(GROFF_IPK_DIR)$(TARGET_PREFIX)/info
	$(MAKE) -C $(GROFF_BUILD_DIR) DESTDIR=$(GROFF_IPK_DIR) install
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/addftinfo
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/eqn
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/grn
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/grodvi
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/groff
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/grolbp
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/grolj4
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/grops
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/grotty
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/hpftodit
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/indxbib
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/lkbib
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/lookbib
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/pfbtops
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/pic
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/post-grohtml
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/pre-grohtml
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/refer
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/soelim
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/tbl
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/tfmtodit
	$(STRIP_COMMAND) $(GROFF_IPK_DIR)$(TARGET_PREFIX)/bin/troff
	rm -f $(GROFF_IPK_DIR)$(TARGET_PREFIX)/info/dir
	rm -f $(GROFF_IPK_DIR)$(TARGET_PREFIX)/info/dir.old
	$(MAKE) $(GROFF_IPK_DIR)/CONTROL/control
	cd $(BUILD_DIR); $(IPKG_BUILD) $(GROFF_IPK_DIR)

#
# This is called from the top level makefile to create the IPK file.
#
groff-ipk: $(GROFF_IPK)

#
# This is called from the top level makefile to clean all of the built files.
#
groff-clean:
	-$(MAKE) -C $(GROFF_BUILD_DIR) clean

#
# This is called from the top level makefile to clean all dynamically created
# directories.
#
groff-dirclean:
	rm -rf $(BUILD_DIR)/$(GROFF_DIR) $(GROFF_BUILD_DIR) $(GROFF_IPK_DIR) $(GROFF_IPK)
#
#
# Some sanity check for the package.
#
groff-check: $(GROFF_IPK)
	perl scripts/optware-check-package.pl --target=$(OPTWARE_TARGET) $^
