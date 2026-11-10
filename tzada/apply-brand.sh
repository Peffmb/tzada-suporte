#!/usr/bin/env bash
# Aplica a marca Tzada no submódulo hbb_common (nome do app, servidor e chave).
set -euo pipefail
CFG=libs/hbb_common/src/config.rs
TZADA_SERVER="${TZADA_SERVER:-163.245.203.148}"
TZADA_KEY="${TZADA_KEY:-KRBSACNCXmb5jCF4mJB9zWIDtwuRMbMogjNTRt7jmWs=}"
sed -i "s|RwLock::new(\"RustDesk\".to_owned())|RwLock::new(\"Tzada\".to_owned())|" "$CFG"
sed -i "s|^pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[.*\];|pub const RENDEZVOUS_SERVERS: \&[\&str] = \&[\"$TZADA_SERVER\"];|" "$CFG"
sed -i "s|^pub const RS_PUB_KEY: &str = \".*\";|pub const RS_PUB_KEY: \&str = \"$TZADA_KEY\";|" "$CFG"
grep -n 'APP_NAME: RwLock\|^pub const RENDEZVOUS_SERVERS\|^pub const RS_PUB_KEY' "$CFG"
grep -q "\"Tzada\"" "$CFG" && grep -q "$TZADA_SERVER" "$CFG" && grep -q "$TZADA_KEY" "$CFG"
