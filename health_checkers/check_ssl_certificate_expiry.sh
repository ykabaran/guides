#!/usr/bin/env bash
set -u

# ============================================================
# CONFIGURATION
# ============================================================

CERT_BASE="${CERT_BASE:-/var/www/certs.hlss.dev}"
WARNING_DAYS="${WARNING_DAYS:-30}"

# Discord notification settings
NOTIFY_SCRIPT="/root/notify_discord.sh"
DISCORD_WEBHOOK_FILE="/root/discord_webhooks/ssl_alerts.txt"

# ============================================================
# SCRIPT
# ============================================================

send_notification() {
    local level=$1
    local title=$2
    local message=$3

    if [ ! -x "$NOTIFY_SCRIPT" ]; then
        echo "ERROR: Discord notifier is not executable: $NOTIFY_SCRIPT" >&2
        return 1
    fi

    if ! "$NOTIFY_SCRIPT" "$DISCORD_WEBHOOK_FILE" "$level" "$title" "$message"; then
        echo "ERROR: Discord notification could not be sent." >&2
        return 1
    fi
}

exit_with_error() {
    local message=$1
    echo "ERROR: $message" >&2
    send_notification error "Certificate expiry check failed" "$message" || true
    exit 2
}

case "$WARNING_DAYS" in
    ''|*[!0-9]*)
        exit_with_error "WARNING_DAYS must be a positive whole number."
        ;;
esac

if [ "$WARNING_DAYS" -le 0 ]; then
    exit_with_error "WARNING_DAYS must be greater than zero."
fi

if [ ! -d "$CERT_BASE" ]; then
    exit_with_error "Certificate directory does not exist: $CERT_BASE"
fi

for command in openssl date find sort; do
    if ! command -v "$command" >/dev/null 2>&1; then
        exit_with_error "Required command is not installed: $command"
    fi
done

now_epoch=$(date +%s)
threshold_seconds=$((WARNING_DAYS * 86400))
checked=0
warnings=0
errors=0
warning_details=""
error_details=""

echo "Checking certificates under: $CERT_BASE"
echo "Warning threshold: fewer than $WARNING_DAYS days remaining"
echo

while IFS= read -r -d '' cert_file; do
    checked=$((checked + 1))
    cert_dir=$(dirname -- "$cert_file")
    cert_name=$(basename -- "$cert_dir")

    if ! end_date_output=$(openssl x509 -in "$cert_file" -noout -enddate 2>/dev/null); then
        echo "ERROR: Could not read certificate: $cert_file" >&2
        errors=$((errors + 1))
        if [ -n "$error_details" ]; then
            error_details+=$'\n'
        fi
        error_details+="Could not read certificate: $cert_file"
        continue
    fi

    end_date=${end_date_output#notAfter=}

    if ! expiry_epoch=$(date -d "$end_date" +%s 2>/dev/null); then
        echo "ERROR: Could not parse expiry date for: $cert_file" >&2
        errors=$((errors + 1))
        if [ -n "$error_details" ]; then
            error_details+=$'\n'
        fi
        error_details+="Could not parse expiry date for: $cert_file"
        continue
    fi

    seconds_left=$((expiry_epoch - now_epoch))

    echo "Certificate: $cert_name"
    echo "Path:        $cert_file"
    echo "Expires:     $end_date"
    days_left=$((seconds_left / 86400))

    if [ "$seconds_left" -lt "$threshold_seconds" ]; then
        warnings=$((warnings + 1))

        if [ "$seconds_left" -le 0 ]; then
            seconds_expired=$((-seconds_left))
            days_expired=$(((seconds_expired + 86399) / 86400))
            echo "Status:      EXPIRED $days_expired day(s) ago"
            warning_line="$cert_name: EXPIRED $days_expired day(s) ago (expired $end_date)"
        else
            echo "Status:      RENEWAL REQUIRED - $days_left day(s) remaining"
            warning_line="$cert_name: $days_left day(s) remaining (expires $end_date)"
        fi

        if [ -n "$warning_details" ]; then
            warning_details+=$'\n'
        fi
        warning_details+="$warning_line"
    else
        echo "Status:      VALID - $days_left day(s) remaining"
    fi
    echo

done < <(find "$CERT_BASE" -mindepth 2 -maxdepth 2 -type f -name server.crt -print0 | sort -z)

if [ "$checked" -eq 0 ]; then
    exit_with_error "No server.crt files were found under $CERT_BASE"
fi

echo "Checked:  $checked certificate(s)"
echo "Warnings: $warnings certificate(s)"
echo "Errors:   $errors certificate(s)"

if [ "$errors" -ne 0 ]; then
    error_message="$errors error(s) occurred while checking certificates under $CERT_BASE:"
    error_message+=$'\n'
    error_message+="$error_details"

    send_notification \
        error \
        "Certificate expiry check errors" \
        "$error_message" || true
fi

if [ "$warnings" -ne 0 ]; then
    warning_message="$warnings certificate(s) have fewer than $WARNING_DAYS days remaining:"
    warning_message+=$'\n'
    warning_message+="$warning_details"

    send_notification \
        warning \
        "Certificates need renewal" \
        "$warning_message" || true
fi

if [ "$errors" -ne 0 ]; then
    exit 2
fi

if [ "$warnings" -ne 0 ]; then
    exit 1
fi

echo "All certificates are outside the renewal warning period."
exit 0
