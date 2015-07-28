# Rozsdamaro

Makefile system for maintaining and building components of the
[Rust world](http://www.rust-lang.org/) with a special focus on AArch64.

See [LICENSE](LICENSE) for copyright and licensing.

## Cargo build rules

* make cargo-build-hash HASH=hhh|nnn
* make cargo-build-hash-log HASH=hhh|nnn
* make cargo-build-master
* make cargo-build-master-log

## Cargo local copy maintenance rules

* make cargo-pull-upstream

## Cargo-related Rozsdamaro maintenance rules

* make cargo-add-rust-hash VERSION=yyyy-mm-dd

## Self-documentation rules

* make doc

## Rust build rules

* make rust-checkout-branch BRANCH=nnn
* make rust-checkout-fork
* make rust-build-branch BRANCH=nnn
* make rust-build-branch-log BRANCH=nnn
* make rust-build-fork
* make rust-build-fork-log
* make rust-build-branch-slave BRANCH=nnn
* make rust-build-branch-slave-log BRANCH=nnn
* make rust-build-fork-slave
* make rust-build-fork-slave-log

## Rust fork maintenance rules

* make rust-mirror-master
* make rust-rebase-fork
* make rust-all-fork
* make rust-all-fork-log
* make rust-create-branch HASH=xxx BRANCH=nnn

## Servo build rules

* make servo-build-hash HASH=hhh|nnn
* make servo-build-hash-log HASH=hhh|nnn
* make servo-build-master
* make servo-build-master-log

## Servo local copy maintenance rules

* make servo-pull-upstream

