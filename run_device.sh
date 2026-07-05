#!/bin/bash
# Lance l'app sur l'iPhone branché en USB (ou premier device iOS détecté),
# avec l'API mon-repas joignable via l'IP du Mac sur le réseau local.
#
# Prérequis : l'API tourne en local (port 3502) et l'iPhone est sur le même Wi-Fi.
#
# Usage :
#   ./run_device.sh                 # détecte l'IP et le device automatiquement
#   ./run_device.sh 192.168.1.42    # force l'IP de l'API

set -euo pipefail

API_PORT=3502

# IP du Mac sur le LAN (Wi-Fi en priorité, sinon Ethernet).
if [ $# -ge 1 ] && [[ "$1" =~ ^[0-9]+\. ]]; then
  MAC_IP="$1"
  shift
else
  MAC_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)
  if [ -z "${MAC_IP}" ]; then
    echo "❌ Impossible de détecter l'IP du Mac. Passe-la en argument : ./run_device.sh 192.168.x.x"
    exit 1
  fi
fi

API_URL="http://${MAC_IP}:${API_PORT}"

# Vérifie que l'API répond avant de builder.
if ! curl -s -o /dev/null --connect-timeout 3 "${API_URL}/api"; then
  echo "⚠️  L'API ne répond pas sur ${API_URL} — vérifie que le backend tourne (start.sh)."
  echo "    On continue quand même (l'app affichera les erreurs réseau)."
fi

echo "📱 API : ${API_URL}"
echo "🚀 flutter run sur le device iOS connecté…"

flutter run \
  --dart-define=MONREPAS_API_URL="${API_URL}" \
  "$@"
