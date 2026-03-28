#!/bin/bash
# notify-discord.sh <STATUS> <PROJECT> <MACHINE> <GPU> <URL> [EXTRA]

STATUS="${1:-UNKNOWN}" PROJECT="${2:-?}" MACHINE="${3:-?}" GPU="${4:-none}" URL="${5:-}" EXTRA="${6:-}"
WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"
[ -z "$WEBHOOK_URL" ] && { echo "No DISCORD_WEBHOOK_URL, skip"; exit 0; }

case "$STATUS" in
  START)     EMOJI="🚀"; COLOR=3447003;  TITLE="Experiment Started" ;;
  DEPLOY)    EMOJI="🌐"; COLOR=3066993;  TITLE="App Deployed" ;;
  success)   EMOJI="✅"; COLOR=3066993;  TITLE="Experiment Succeeded" ;;
  failure)   EMOJI="❌"; COLOR=15158332; TITLE="Experiment Failed" ;;
  cancelled) EMOJI="⏹️"; COLOR=9807270;  TITLE="Experiment Cancelled" ;;
  *)         EMOJI="❓"; COLOR=9807270;  TITLE="Status: $STATUS" ;;
esac

FIELDS=$(jq -n \
  --arg project "$PROJECT" \
  --arg machine "$MACHINE" \
  --arg gpu "$GPU" \
  '[
    {name: "Project", value: ("`" + $project + "`"), inline: true},
    {name: "Machine", value: ("`" + $machine + "`"), inline: true},
    {name: "GPU", value: ("`" + $gpu + "`"), inline: true}
  ]')

if [ -n "$EXTRA" ]; then
  FIELDS=$(echo "$FIELDS" | jq --arg extra "$EXTRA" '. + [{name: "Note", value: $extra, inline: false}]')
fi

PAYLOAD=$(jq -n \
  --arg title "$EMOJI $TITLE" \
  --argjson color "$COLOR" \
  --argjson fields "$FIELDS" \
  --arg url "$URL" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{embeds: [{title: $title, color: $color, fields: $fields, url: $url, timestamp: $ts}]}')

curl -s -X POST "$WEBHOOK_URL" -H "Content-Type: application/json" -d "$PAYLOAD"
