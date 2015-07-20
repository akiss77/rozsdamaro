# Rozsdamaro
#
# Makefile system for maintaining and building components of the Rust world
# with a special focus on AArch64
#
# Copyright (C) 2014-2015, University of Szeged
# Copyright (C) 2014-2015, Akos Kiss <akiss@inf.u-szeged.hu>


################################################################################
# Configuration

# User/setup-specific config read-in

include config.mk

# Fixed settings (for now, at least)

IDENT:=RZSD
BUILD_ARCH:=$(shell uname -m)
BUILD_TRIPLE:=$(BUILD_ARCH)-unknown-linux-gnu
TARGET_ARCH:=aarch64
TARGET_TRIPLE:=$(TARGET_ARCH)-unknown-linux-gnu

ifneq ($(BUILD_ARCH),$(TARGET_ARCH))
XBUILT:=-x
else
XBUILT:=
endif

# Directory shorthands

RZSD_DIR:=$(RZSD_DIR_$(BUILD_ARCH))
STORE_DIR:=$(RZSD_DIR)/store
INST_DIR:=$(INST_DIR_$(BUILD_ARCH))


################################################################################
# Default rule to avoid any executions by mistake

default:
	@echo "$(IDENT): Error: Default make target unsupported. Please specify target explicitly." && false


################################################################################
# Component-specific rules

include mk/rust.mk
