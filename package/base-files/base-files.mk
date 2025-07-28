#
# Base-files consolidation for IPQ chipsets
#

BASEFILES_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

define base-files_install_append
	$(CP) -a $(BASEFILES_DIR)/files/. $(1)/
endef

Package/base-files/install += $(newline)$(base-files_install_append)
