# Recipe extension for package : pwhm

PWHM_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

define pwhm_install_append
	$(CP) -a $(PWHM_DIR)/files/. $(1)/
endef

Package/pwhm/install += $(newline)$(pwhm_install_append)
