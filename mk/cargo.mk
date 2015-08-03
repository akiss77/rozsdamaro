# Rozsdamaro -- Cargo-specific rules
#
# Copyright (c) 2015, University of Szeged
# Copyright (c) 2015, Akos Kiss <akiss@inf.u-szeged.hu>

include mk/cargo-rustversion.mk


################################################################################
# General directory shorthand

CARGO_SRC_DIR:=$(CARGO_SRC_DIR_$(BUILD_ARCH))


################################################################################
## ## Cargo build rules
##
## * make cargo-build-hash HASH=hhh|nnn
## * make cargo-build-hash-log HASH=hhh|nnn
## * make cargo-build-master
## * make cargo-build-master-log
##

CARGO_HASH_OUT:=$(shell mktemp --tmpdir --dry-run rzsd-cargo-hash.XXXXXXXXXX)
CARGO_TIME_OUT:=$(shell mktemp --tmpdir --dry-run rzsd-cargo-time.XXXXXXXXXX)
CARGO_RUST_ROOT:=$(shell mktemp --tmpdir --dry-run rzsd-cargo-rustroot.XXXXXXXXXX)
CARGO_PKG_ID=cargo-`cat $(CARGO_TIME_OUT)`-`cat $(CARGO_HASH_OUT)`
CARGO_LATEST:=cargo-latest

.PHONY: cargo-build-hash
cargo-build-hash: $(STORE_DIR)
	@[ -n "$(HASH)" ] || ( echo "$(IDENT): Error: Please specify HASH to build." && false )
	cd $(CARGO_SRC_DIR) && git checkout $(HASH)
	cd $(CARGO_SRC_DIR) && git rev-parse --short $(HASH) >$(CARGO_HASH_OUT)
	cd $(CARGO_SRC_DIR) && date -u +%Y%m%d-%H%M%S -d "$$(git show `cat $(CARGO_HASH_OUT)` --format=format:%cd --date=iso | head -1)" >$(CARGO_TIME_OUT)
	@echo "$(IDENT): Cargo hash is `cat $(CARGO_HASH_OUT)`"
	@echo "$(IDENT): Cargo commit date is `cat $(CARGO_TIME_OUT)`"
	@echo "$(IDENT): Cargo build started at `date -u +%Y%m%d-%H%M%S`"
	@echo "$(IDENT): Cargo build/target architecture is $(BUILD_ARCH)/$(TARGET_ARCH)"
	@echo "$(IDENT): Cargo build uses MAKEFLAGS=\"$(MAKEFLAGS)\""
	
	-$(MAKE) -C $(CARGO_SRC_DIR) clean
	ls -d $(INST_DIR)/rust-*-$(CARGO_RUST_$(shell cat $(CARGO_SRC_DIR)/src/rustversion.txt)) >$(CARGO_RUST_ROOT)
	cd $(CARGO_SRC_DIR) && ./configure --local-rust-root=`cat $(CARGO_RUST_ROOT)` --local-cargo=$(INST_DIR)/$(CARGO_LATEST)/bin/cargo --prefix=$(INST_DIR)/$(CARGO_PKG_ID)
	$(MAKE) -C $(CARGO_SRC_DIR) VERBOSE=1
	
	$(MAKE) -C $(CARGO_SRC_DIR) install
	[ "$(HASH)" != "master" ] || ( cd $(INST_DIR) && ln -sfT $(CARGO_PKG_ID) $(CARGO_LATEST) )
	
	cd $(INST_DIR) && tar cvfj $(STORE_DIR)/$(CARGO_PKG_ID)-$(TARGET_ARCH)-inst.tar.bz2 $(CARGO_PKG_ID)
	[ "$(HASH)" != "master" ] || ( cd $(STORE_DIR) && ln -sfT $(CARGO_PKG_ID)-$(TARGET_ARCH)-inst.tar.bz2 $(CARGO_LATEST)-$(TARGET_ARCH)-inst.tar.bz2 )
	
	@echo "$(IDENT): Cargo build finished at `date -u +%Y%m%d-%H%M%S`"
	rm -f $(CARGO_HASH_OUT)
	rm -f $(CARGO_TIME_OUT)
	rm -f $(CARGO_RUST_ROOT)

.PHONY: cargo-build-master
cargo-build-master:
	$(MAKE) -C $(RZSD_DIR) cargo-build-hash HASH=master

.PHONY: cargo-build-hash-log
cargo-build-hash-log: $(STORE_DIR)
	( time $(MAKE) -C $(RZSD_DIR) cargo-build-hash 2>&1 ) | tee $(STORE_DIR)/$(CARGO_LATEST)-$(TARGET_ARCH)-log$(XBUILT).txt
	cd $(CARGO_SRC_DIR) && git rev-parse --short $(HASH) >$(CARGO_HASH_OUT)
	cd $(CARGO_SRC_DIR) && date -u +%Y%m%d-%H%M%S -d "$$(git show `cat $(CARGO_HASH_OUT)` --format=format:%cd --date=iso | head -1)" >$(CARGO_TIME_OUT)
	mv $(STORE_DIR)/$(CARGO_LATEST)-$(TARGET_ARCH)-log$(XBUILT).txt $(STORE_DIR)/$(CARGO_PKG_ID)-$(TARGET_ARCH)-log$(XBUILT).txt
	rm -f $(CARGO_HASH_OUT)
	rm -f $(CARGO_TIME_OUT)

.PHONY: cargo-build-master-log
cargo-build-master-log:
	$(MAKE) -C $(RZSD_DIR) cargo-build-hash-log HASH=master


################################################################################
## ## Cargo local copy and mirror maintenance rules
##
## * make cargo-pull-upstream
## * make cargo-mirror-master
##

.PHONY: cargo-pull-upstream
cargo-pull-upstream:
	cd $(CARGO_SRC_DIR) && git fetch $(CARGO_UPSTREAM_REMOTE)
	cd $(CARGO_SRC_DIR) && git checkout master
	cd $(CARGO_SRC_DIR) && git merge --ff-only $(CARGO_UPSTREAM_REMOTE)/master

.PHONY: cargo-mirror-master
cargo-mirror-master: cargo-pull-upstream
	cd $(CARGO_SRC_DIR) && git submodule update
	cd $(CARGO_SRC_DIR) && git push $(CARGO_MIRROR_REMOTE) master


################################################################################
## ## Cargo-related Rozsdamaro maintenance rules
##
## * make cargo-add-rust-hash VERSION=yyyy-mm-dd
##

CARGO_RUST_DOC_TGZ:=$(shell mktemp --tmpdir --dry-run rzsd-cargo-rustdoc.XXXXXXXXXX)
CARGO_RUST_HASH:=$(shell mktemp --tmpdir --dry-run rzsd-cargo-rusthash.XXXXXXXXXX)
CARGO_FIXED_TRIPLE:=x86_64-unknown-linux-gnu

.PHONY: cargo-add-rust-hash
cargo-add-rust-hash:
	@[ -n "$(VERSION)" ] || ( echo "$(IDENT): Error: Please specify VERSION (i.e., date) of nightly rust." && false )
	curl -L https://static.rust-lang.org/dist/$(VERSION)/rust-docs-nightly-$(CARGO_FIXED_TRIPLE).tar.gz -o $(CARGO_RUST_DOC_TGZ)
	tar xfzO $(CARGO_RUST_DOC_TGZ) rust-docs-nightly-$(CARGO_FIXED_TRIPLE)/rust-docs/share/doc/rust/html/version_info.html | grep -o "commit/\\w\{7\}" | cut -c 8- >$(CARGO_RUST_HASH)
	rm $(CARGO_RUST_DOC_TGZ)
	echo "CARGO_RUST_$(VERSION):=`cat $(CARGO_RUST_HASH)`" >>mk/cargo-rustversion.mk
	rm $(CARGO_RUST_HASH)
