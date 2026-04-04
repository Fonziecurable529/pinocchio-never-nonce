RUST_TOOLCHAIN = 1.89.0
RUST_TOOLCHAIN_NIGHTLY = nightly-2026-01-22
SOLANA_CLI_VERSION = 3.0.0

nightly = +${RUST_TOOLCHAIN_NIGHTLY}

# This is a bit tricky -- findstring returns the found string, so we're looking
# for "directory-", returning that, and replacing "-" with "/" to change the
# first "-" to a "/". But if it isn't found, we replace "" with "", which works
# in the case where there is no subdirectory.
pattern-dir = $(firstword $(subst -, ,$1))
find-pattern-dir = $(findstring $(call pattern-dir,$1)-,$1)
make-path = $(subst $(call find-pattern-dir,$1),$(subst -,/,$(call find-pattern-dir,$1)),$1)

rust-toolchain:
	@echo ${RUST_TOOLCHAIN}

rust-toolchain-nightly:
	@echo ${RUST_TOOLCHAIN_NIGHTLY}

solana-cli-version:
	@echo ${SOLANA_CLI_VERSION}

cargo-nightly:
	cargo $(nightly) $(ARGS)

audit:
	cargo audit \
			--ignore RUSTSEC-2022-0093 \
			--ignore RUSTSEC-2024-0344 \
			--ignore RUSTSEC-2024-0376 $(ARGS)

spellcheck:
	cargo spellcheck --code 1 $(ARGS)

clippy-%:
	cargo $(nightly) clippy --manifest-path $(call make-path,$*)/Cargo.toml \
	  --all-targets \
	  --all-features \
		-- \
		--deny=warnings \
		--deny=clippy::default_trait_access \
		--deny=clippy::arithmetic_side_effects \
		--deny=clippy::manual_let_else \
		--deny=clippy::used_underscore_binding $(ARGS)

format-check-%:
	cargo $(nightly) fmt --check --manifest-path $(call make-path,$*)/Cargo.toml $(ARGS)

sort-check:
	cargo $(nightly) sort --workspace --check $(ARGS)

format-rust:
	cargo $(nightly) fmt --all $(ARGS)

build-sbf-%:
	cargo build-sbf --manifest-path $(call make-path,$*)/Cargo.toml --tools-version v1.54 $(ARGS)

test-%:
	SBF_OUT_DIR=$(PWD)/target/deploy cargo $(nightly) test --manifest-path $(call make-path,$*)/Cargo.toml $(ARGS)
