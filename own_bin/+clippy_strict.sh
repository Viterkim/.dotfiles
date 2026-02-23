#!/usr/bin/env bash
cargo clippy --release --all-targets --all-features -- -W clippy::all
