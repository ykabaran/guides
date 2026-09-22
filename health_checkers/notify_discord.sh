#!/usr/bin/env bash

# Send a monitoring notification to a Discord channel.
#
# Usage:
#   ./notify_discord.sh WEBHOOK_FILE LEVEL TITLE MESSAGE
#
# Levels:
#   info, success, warning, error, critical
#
# WEBHOOK_FILE must contain a Discord webhook URL on its first line.

set -u

usage() {
    printf 'Usage: %s WEBHOOK_FILE LEVEL TITLE MESSAGE\n' "${0##*/}" >&2
    printf 'Levels: info, success, warning, error, critical\n' >&2
}

json_escape() {
    local value=$1
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/\\r}
    value=${value//$'\t'/\\t}
    printf '%s' "$value"
}

if (( $# != 4 )); then
    usage
    exit 2
fi

webhook_file=$1
level=${2,,}
title=$3
message=$4

case "$level" in
    info)     color=3447003 ;;
    success)  color=5763719 ;;
    warning)  color=16776960 ;;
    error)    color=15548997 ;;
    critical) color=10038562 ;;
    *)
        printf 'Error: unsupported notification level: %s\n' "$level" >&2
        usage
        exit 2
        ;;
esac

if [[ ! -r "$webhook_file" ]]; then
    printf 'Error: Discord webhook file is not readable: %s\n' "$webhook_file" >&2
    exit 2
fi

IFS= read -r webhook_url < "$webhook_file" || true
webhook_url=${webhook_url%$'\r'}

case "$webhook_url" in
    https://discord.com/api/webhooks/*|https://discordapp.com/api/webhooks/*) ;;
    *)
        printf 'Error: the configured value is not a valid Discord webhook URL.\n' >&2
        exit 2
        ;;
esac

# Discord embed field limits. Truncate locally so an unexpectedly large error
# message does not cause the entire notification to be rejected.
if (( ${#title} > 256 )); then
    title="${title:0:253}..."
fi
if (( ${#message} > 4096 )); then
    message="${message:0:4093}..."
fi

host_name=$(hostname 2>/dev/null || printf 'unknown')
timestamp=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

payload=$(printf \
    '{"username":"Server Monitor","embeds":[{"title":"%s","description":"%s","color":%s,"fields":[{"name":"Severity","value":"%s","inline":true},{"name":"Host","value":"%s","inline":true}],"timestamp":"%s"}]}' \
    "$(json_escape "$title")" \
    "$(json_escape "$message")" \
    "$color" \
    "$(json_escape "${level^^}")" \
    "$(json_escape "$host_name")" \
    "$timestamp")

if ! curl \
    --fail \
    --silent \
    --show-error \
    --connect-timeout 10 \
    --max-time 30 \
    --retry 3 \
    --retry-delay 2 \
    --header 'Content-Type: application/json' \
    --request POST \
    --data-binary "$payload" \
    "$webhook_url"; then
    printf 'Error: Discord notification could not be delivered.\n' >&2
    exit 1
fi

printf 'Discord notification delivered successfully.\n'
