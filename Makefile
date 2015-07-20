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

# Directory shorthands

RZSD_DIR:=$(RZSD_DIR_$(BUILD_ARCH))
STORE_DIR:=$(RZSD_DIR)/store
INST_DIR:=$(INST_DIR_$(BUILD_ARCH))

RUST_SRC_DIR:=$(RUST_SRC_DIR_$(BUILD_ARCH))


################################################################################
# Default rule to avoid any executions by mistake

default:
	@echo "$(IDENT): Error: Default make target unsupported. Please specify target explicitly." && false

	
################################################################################
# Rust build rules
#
# make rust-checkout-branch BRANCH=nnn
# make rust-checkout-fork
# make rust-build-branch BRANCH=nnn
# make rust-build-branch-log BRANCH=nnn
# make rust-build-fork
# make rust-build-fork-log
# make rust-build-branch-slave BRANCH=nnn
# make rust-build-branch-slave-log BRANCH=nnn
# make rust-build-fork-slave
# make rust-build-fork-slave-log

RUST_HASH_OUT:=$(shell mktemp --tmpdir --dry-run rzsd-rust-hash.XXXXXXXXXX)
RUST_TIME_OUT:=$(shell mktemp --tmpdir --dry-run rzsd-rust-time.XXXXXXXXXX)
RUST_SNAP_OUT:=$(shell mktemp --tmpdir --dry-run rzsd-rust-snap.XXXXXXXXXX)
RUST_PKG_ID=rust-`cat $(RUST_TIME_OUT)`-`cat $(RUST_HASH_OUT)`
RUST_LATEST:=rust-latest

.PHONY: internal-rust-checkout-branch-pre
internal-rust-checkout-branch-pre:
	@[ -n "$(BRANCH)" ] || ( echo "$(IDENT): Error: Please specify BRANCH to build." && false )
	cd $(RUST_SRC_DIR) && git fetch $(RUST_FORK_REMOTE)
	cd $(RUST_SRC_DIR) && git checkout $(BRANCH)
	cd $(RUST_SRC_DIR) && git reset --hard $(RUST_FORK_REMOTE)/$(BRANCH)
	cd $(RUST_SRC_DIR) && git submodule update
	cd $(RUST_SRC_DIR) && git merge-base $(BRANCH) master | cut -c 1-7 >$(RUST_HASH_OUT)
	cd $(RUST_SRC_DIR) && date -u +%Y%m%d-%H%M%S -d "$$(git show `cat $(RUST_HASH_OUT)` --format=format:%cd --date=iso | head -1)" >$(RUST_TIME_OUT)
	@echo "$(IDENT): Rust hash is `cat $(RUST_HASH_OUT)`"
	@echo "$(IDENT): Rust commit date is `cat $(RUST_TIME_OUT)`"

.PHONY: rust-checkout-branch
rust-checkout-branch: internal-rust-checkout-branch-pre
	rm -f $(RUST_HASH_OUT)
	rm -f $(RUST_TIME_OUT)

.PHONY: rust-checkout-fork
rust-checkout-fork:
	$(MAKE) -C $(RZSD_DIR) rust-checkout-branch BRANCH=$(RUST_FORK_MASTER)

.PHONY: internal-rust-build-branch-pre
internal-rust-build-branch-pre: internal-rust-checkout-branch-pre
	@echo "$(IDENT): Rust build started at `date -u +%Y%m%d-%H%M%S`"
	@echo "$(IDENT): Rust build/target architecture is $(BUILD_ARCH)/$(TARGET_ARCH)"
	
ifneq ($(BUILD_ARCH),$(TARGET_ARCH))

RUST_XSUFF:=-x
export PATH:=$(GCC_BIN_DIR_$(BUILD_ARCH)_X_$(TARGET_ARCH)):$(PATH)

.PHONY: internal-rust-build-branch-main
internal-rust-build-branch-main: internal-rust-build-branch-pre
	-$(MAKE) -C $(RUST_SRC_DIR) clean
	cd $(RUST_SRC_DIR) && ./configure --host=$(BUILD_TRIPLE),$(TARGET_TRIPLE) --target=$(TARGET_TRIPLE) --disable-valgrind --disable-docs --prefix=$(INST_DIR)/$(RUST_PKG_ID)
	$(MAKE) -C $(RUST_SRC_DIR) VERBOSE=1
	
	$(MAKE) -C $(RUST_SRC_DIR) snap-stage3-H-$(TARGET_TRIPLE) VERBOSE=1 | tee $(RUST_SNAP_OUT)
	grep rust-stage0-.*.tar.bz2 $(RUST_SNAP_OUT) && \
	  mv $(RUST_SRC_DIR)/`grep rust-stage0-.*.tar.bz2 $(RUST_SNAP_OUT)` $(STORE_DIR)/$(RUST_PKG_ID)-$(TARGET_ARCH)-snap$(RUST_XSUFF).tar.bz2
	rm -f $(RUST_SNAP_OUT)
	cd $(STORE_DIR) && ln -sf $(RUST_PKG_ID)-$(TARGET_ARCH)-snap$(RUST_XSUFF).tar.bz2 $(RUST_LATEST)-$(TARGET_ARCH)-snap$(RUST_XSUFF).tar.bz2

else

RUST_XSUFF:=
RUST_SNAPSHOT_FILE=$(shell cd $(STORE_DIR) && ls -f $(RUST_PKG_ID)-$(TARGET_ARCH)-snap-x.tar.bz2 $(RUST_LATEST)-$(TARGET_ARCH)-snap-x.tar.bz2 $(RUST_LATEST)-$(TARGET_ARCH)-snap.tar.bz2 | head -1)

.PHONY: internal-rust-build-branch-main
internal-rust-build-branch-main: internal-rust-build-branch-pre
	-$(MAKE) -C $(RUST_SRC_DIR) clean
	cd $(RUST_SRC_DIR) && ./configure --disable-valgrind --prefix=$(INST_DIR)/$(RUST_PKG_ID)
	$(MAKE) -C $(RUST_SRC_DIR) VERBOSE=1 HIDE_STAGE0=1 SNAPSHOT_FILE=$(STORE_DIR)/$(RUST_SNAPSHOT_FILE)
	
	$(MAKE) -C $(RUST_SRC_DIR) snap-stage3 | tee $(RUST_SNAP_OUT)
	grep rust-stage0-.*.tar.bz2 $(RUST_SNAP_OUT) && \
	  mv $(RUST_SRC_DIR)/`grep rust-stage0-.*.tar.bz2 $(RUST_SNAP_OUT)` $(STORE_DIR)/$(RUST_PKG_ID)-$(TARGET_ARCH)-snap$(RUST_XSUFF).tar.bz2
	rm -f $(RUST_SNAP_OUT)
	cd $(STORE_DIR) && ln -sf $(RUST_PKG_ID)-$(TARGET_ARCH)-snap$(RUST_XSUFF).tar.bz2 $(RUST_LATEST)-$(TARGET_ARCH)-snap$(RUST_XSUFF).tar.bz2
	
	$(MAKE) -C $(RUST_SRC_DIR) install
	cd $(INST_DIR) && ln -sf $(RUST_PKG_ID) $(RUST_LATEST)
	
	cd $(INST_DIR) && tar cvfj $(STORE_DIR)/$(RUST_PKG_ID)-$(TARGET_ARCH)-inst$(RUST_XSUFF).tar.bz2 $(RUST_PKG_ID)
	cd $(STORE_DIR) && ln -sf $(RUST_PKG_ID)-$(TARGET_ARCH)-inst$(RUST_XSUFF).tar.bz2 $(RUST_LATEST)-$(TARGET_ARCH)-inst$(RUST_XSUFF).tar.bz2

endif

.PHONY: rust-build-branch
rust-build-branch: internal-rust-build-branch-main
	@echo "$(IDENT): Rust build finished at `date -u +%Y%m%d-%H%M%S`"
	rm -f $(RUST_HASH_OUT)
	rm -f $(RUST_TIME_OUT)

.PHONY: rust-build-branch-log
rust-build-branch-log:
	( time $(MAKE) -C $(RZSD_DIR) rust-build-branch 2>&1 ) | tee $(STORE_DIR)/$(RUST_LATEST)-$(TARGET_ARCH)-log$(RUST_XSUFF).txt
	cd $(RUST_SRC_DIR) && git merge-base $(BRANCH) master | cut -c 1-7 >$(RUST_HASH_OUT)
	cd $(RUST_SRC_DIR) && date -u +%Y%m%d-%H%M%S -d "$$(git show `cat $(RUST_HASH_OUT)` --format=format:%cd --date=iso | head -1)" >$(RUST_TIME_OUT)
	mv $(STORE_DIR)/$(RUST_LATEST)-$(TARGET_ARCH)-log$(RUST_XSUFF).txt $(STORE_DIR)/$(RUST_PKG_ID)-$(TARGET_ARCH)-log$(RUST_XSUFF).txt
	rm -f $(RUST_HASH_OUT)
	rm -f $(RUST_TIME_OUT)

.PHONY: rust-build-fork
rust-build-fork:
	$(MAKE) -C $(RZSD_DIR) rust-build-branch BRANCH=$(RUST_FORK_MASTER)

.PHONY: rust-build-fork-log
rust-build-fork-log:
	$(MAKE) -C $(RZSD_DIR) rust-build-branch-log BRANCH=$(RUST_FORK_MASTER)

ifneq ($(BUILD_ARCH),$(TARGET_ARCH))

.PHONY: rust-build-branch-slave
rust-build-branch-slave: rust-build-branch
	ssh $(SLAVE_$(TARGET_ARCH)) "make -j -C $(RZSD_DIR_$(TARGET_ARCH)) rust-build-branch BRANCH=$(BRANCH)"

.PHONY: rust-build-branch-slave-log
rust-build-branch-slave-log:
	( time $(MAKE) -C $(RZSD_DIR) rust-build-branch-slave 2>&1 ) | tee $(STORE_DIR)/$(RUST_LATEST)-$(TARGET_ARCH)-log-slave.txt
	cd $(RUST_SRC_DIR) && git merge-base $(BRANCH) master | cut -c 1-7 >$(RUST_HASH_OUT)
	cd $(RUST_SRC_DIR) && date -u +%Y%m%d-%H%M%S -d "$$(git show `cat $(RUST_HASH_OUT)` --format=format:%cd --date=iso | head -1)" >$(RUST_TIME_OUT)
	mv $(STORE_DIR)/$(RUST_LATEST)-$(TARGET_ARCH)-log-slave.txt $(STORE_DIR)/$(RUST_PKG_ID)-$(TARGET_ARCH)-log-slave.txt
	rm -f $(RUST_HASH_OUT)
	rm -f $(RUST_TIME_OUT)

.PHONY: rust-build-fork-slave
rust-build-fork-slave:
	$(MAKE) -C $(RZSD_DIR) rust-build-branch-slave BRANCH=$(RUST_FORK_MASTER)

.PHONY: rust-build-fork-slave-log
rust-build-fork-slave-log:
	$(MAKE) -C $(RZSD_DIR) rust-build-branch-slave-log BRANCH=$(RUST_FORK_MASTER)

endif


################################################################################
# Rust maintenance rules
#
# make rust-mirror-master
# make rust-rebase-fork
# make rust-all-fork
# make rust-all-fork-log
# make rust-create-branch HASH=xxx BRANCH=nnn

.PHONY: rust-mirror-master
rust-mirror-master:
	cd $(RUST_SRC_DIR) && git fetch $(RUST_UPSTREAM_REMOTE)
	cd $(RUST_SRC_DIR) && git checkout master
	cd $(RUST_SRC_DIR) && git merge --ff-only $(RUST_UPSTREAM_REMOTE)/master
	cd $(RUST_SRC_DIR) && git submodule update
	cd $(RUST_SRC_DIR) && git push $(RUST_FORK_REMOTE) master

.PHONY: rust-rebase-fork
rust-rebase-fork: rust-mirror-master
	cd $(RUST_SRC_DIR) && git checkout $(RUST_FORK_MASTER)
	cd $(RUST_SRC_DIR) && git rebase master || ( git rebase --abort && false )
	cd $(RUST_SRC_DIR) && git push -f $(RUST_FORK_REMOTE) $(RUST_FORK_MASTER)

.PHONY: rust-all-fork
rust-all-fork:
	$(MAKE) -C $(RZSD_DIR) rust-rebase-fork
	$(MAKE) -C $(RZSD_DIR) rust-build-fork-slave
	
.PHONY: rust-all-fork-log
rust-all-fork-log:
	( time $(MAKE) -C $(RZSD_DIR) rust-all-fork 2>&1 ) | tee $(STORE_DIR)/$(RUST_LATEST)-$(TARGET_ARCH)-log-all.txt
	cd $(RUST_SRC_DIR) && git merge-base $(BRANCH) master | cut -c 1-7 >$(RUST_HASH_OUT)
	cd $(RUST_SRC_DIR) && date -u +%Y%m%d-%H%M%S -d "$$(git show `cat $(RUST_HASH_OUT)` --format=format:%cd --date=iso | head -1)" >$(RUST_TIME_OUT)
	mv $(STORE_DIR)/$(RUST_LATEST)-$(TARGET_ARCH)-log-all.txt $(STORE_DIR)/$(RUST_PKG_ID)-$(TARGET_ARCH)-log-all.txt
	rm -f $(RUST_HASH_OUT)
	rm -f $(RUST_TIME_OUT)

.PHONY: rust-create-branch
rust-create-branch:
	@[ -n "$(HASH)" -a -n "$(BRANCH)" ] || ( echo "$(IDENT): Error: Please specify HASH to fork off and BRANCH for the new name." && false )
	cd $(RUST_SRC_DIR) && git checkout $(RUST_FORK_MASTER)
	cd $(RUST_SRC_DIR) && git checkout -b $(BRANCH)
	cd $(RUST_SRC_DIR) && git rebase --onto $(HASH) master $(BRANCH)
	cd $(RUST_SRC_DIR) && git submodule update
