#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$RUNNER_TEMP/validation"
git rev-parse HEAD > "$RUNNER_TEMP/validation/source.txt"
sha256sum Cargo.lock > "$RUNNER_TEMP/validation/lock.txt"
mapfile -t members < <(cargo metadata --locked --no-deps --format-version 1 | jq -r '.workspace_members[]')
for member in "${members[@]}"; do cargo check --locked -p "$member" --no-default-features; done
for member in "${members[@]}"; do cargo check --locked -p "$member"; done
cargo build --locked --workspace --tests --examples --release

iota-localnet start --with-faucet --with-grpc > "$RUNNER_TEMP/validation/iota.log" 2>&1 &
for attempt in {1..60}; do
  if iota client new-env --alias localnet --rpc http://127.0.0.1:9000 --grpc http://127.0.0.1:50051 --faucet http://127.0.0.1:9123/v1/gas --json; then break; fi
  if [[ "$attempt" == 60 ]]; then exit 1; fi
  sleep 1
done
iota client switch --env localnet
test "$(iota client active-env --json | jq -r '.')" = localnet
(cd notarization-move && iota move test)
(cd audit-trail-move && iota move test)
IOTA_NOTARIZATION_PKG_ID=$(notarization-move/scripts/publish_package.sh)
export IOTA_NOTARIZATION_PKG_ID
eval "$(audit-trail-move/scripts/publish_package.sh)"
cargo test --locked --workspace --release -- --test-threads=1
cargo metadata --locked --format-version 1 --manifest-path examples/Cargo.toml |
  jq -r '.packages[] | select(.name == "examples") | .targets[].name' |
  awk '$1 ~ /[0-9].*/' |
  parallel -k -j 4 --retries 3 --joblog "$RUNNER_TEMP/validation/examples.log" ./target/release/examples/{}
export IOTA_GENESIS_PATH="$HOME/.iota/iota_config/genesis.blob"
./examples/poi/run.sh

git status --short > "$RUNNER_TEMP/validation/generated-state.txt"
sccache --show-stats > "$RUNNER_TEMP/validation/sccache.txt"
