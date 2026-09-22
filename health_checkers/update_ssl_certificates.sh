#!/usr/bin/env bash
set -u

# This script uses exit codes and traps, so it must run in its own process.
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    echo "ERROR: Do not source this script." >&2
    echo "Run it as: ./update_ssl_certificates.sh" >&2
    return 1
fi

# ============================================================
# CONFIGURATION
# ============================================================

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_file=${1:-"$script_dir/update_ssl_certificates.conf"}
NOTIFY_SCRIPT="$script_dir/notify_discord.sh"
DISCORD_WEBHOOK_FILE="$script_dir/discord_webhooks/ssl_alerts.txt"

notify_configuration_error() {
    local message=$1

    if [ -x "$NOTIFY_SCRIPT" ] && [ -r "$DISCORD_WEBHOOK_FILE" ]; then
        "$NOTIFY_SCRIPT" \
            "$DISCORD_WEBHOOK_FILE" \
            error \
            "SSL updater configuration error" \
            "$message" || true
    fi
}

if [ "$#" -gt 1 ]; then
    echo "Usage: ${0##*/} [CONFIG_FILE]" >&2
    exit 2
fi

if [ ! -r "$config_file" ]; then
    echo "ERROR: Configuration file is not readable: $config_file" >&2
    notify_configuration_error "Configuration file is not readable: $config_file"
    exit 1
fi

CERT_SERVER=""
CERTS=""
EMPTY_CHAIN_CERTS=""
TARGET_BASE=""
RESTART_CMD=""
config_error=0

# The config format is KEY=VALUE, without quotes or spaces around the equals
# sign. Only the known keys below are accepted; the file is not executed.
while IFS='=' read -r config_key config_value || [ -n "$config_key" ]; do
    config_key=${config_key%$'\r'}
    config_value=${config_value%$'\r'}

    case "$config_key" in
        ''|'#'*)
            continue
            ;;
        CERT_SERVER|CERTS|EMPTY_CHAIN_CERTS|TARGET_BASE|RESTART_CMD|NOTIFY_SCRIPT|DISCORD_WEBHOOK_FILE)
            printf -v "$config_key" '%s' "$config_value"
            ;;
        *)
            echo "ERROR: Unknown configuration key: $config_key" >&2
            config_error=1
            ;;
    esac
done < "$config_file"

if [ "$config_error" -ne 0 ]; then
    notify_configuration_error "The configuration file contains one or more unknown keys: $config_file"
    exit 1
fi

for required_key in CERT_SERVER CERTS TARGET_BASE RESTART_CMD NOTIFY_SCRIPT DISCORD_WEBHOOK_FILE; do
    if [ -z "${!required_key}" ]; then
        echo "ERROR: Required configuration value is missing: $required_key" >&2
        config_error=1
    fi
done

if [ "$config_error" -ne 0 ]; then
    notify_configuration_error "The configuration file is missing one or more required values: $config_file"
    exit 1
fi

# ============================================================
# SCRIPT
# ============================================================

changed=0
failed=0
work_dir=""
backup_dir=""
install_started=0
update_committed=0
rollback_done=0
failure_message=""
updated_certs=""

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

cleanup() {
    status=$?
    trap - EXIT

    if [ "$install_started" -eq 1 ] && [ "$update_committed" -eq 0 ]; then
        rollback_files
    fi

    if [ -n "$work_dir" ] && [ -d "$work_dir" ]; then
        rm -rf -- "$work_dir"
    fi

    if [ "$status" -ne 0 ]; then
        send_notification \
            error \
            "SSL certificate update failed" \
            "${failure_message:-The update script exited unexpectedly. Check the server log for details.}" || true
    fi

    exit "$status"
}

rollback_files() {
    if [ "$rollback_done" -eq 1 ]; then
        return
    fi

    rollback_done=1
    echo "Restoring previous certificate files..." >&2

    for cert in $CERTS; do
        for file in server.crt chain.crt bundle.crt; do
            marker="$backup_dir/$cert/$file.changed"

            if [ ! -f "$marker" ]; then
                continue
            fi

            target="$TARGET_BASE/$cert/$file"
            backup="$backup_dir/$cert/$file"

            if [ -e "$backup" ] || [ -L "$backup" ]; then
                mv -f -- "$backup" "$target"
            else
                rm -f -- "$target"
            fi
        done
    done
}

trap cleanup EXIT
trap 'failure_message="The update script was interrupted by a signal."; exit 1' HUP INT TERM

if ! mkdir -p "$TARGET_BASE"; then
    echo "ERROR: Could not create certificate directory: $TARGET_BASE" >&2
    failure_message="Could not create certificate directory: $TARGET_BASE"
    exit 1
fi

if ! work_dir=$(mktemp -d "$TARGET_BASE/.ssl-update.XXXXXX"); then
    echo "ERROR: Could not create temporary update directory." >&2
    failure_message="Could not create a temporary update directory under $TARGET_BASE."
    exit 1
fi

backup_dir="$work_dir/backups"
if ! mkdir -p "$backup_dir"; then
    echo "ERROR: Could not create temporary backup directory." >&2
    failure_message="Could not create the temporary certificate backup directory."
    exit 1
fi

# Download all files and build all bundles before changing live files.
for cert in $CERTS; do
    echo "Checking certificate: $cert"

    stage_dir="$work_dir/downloads/$cert"
    mkdir -p "$stage_dir"
    cert_failed=0

    for file in server.crt chain.crt; do
        url="$CERT_SERVER/$cert/$file"
        staged="$stage_dir/$file"

        echo "  Downloading $url"

        if ! curl \
            --fail \
            --silent \
            --show-error \
            --location \
            --connect-timeout 15 \
            --max-time 60 \
            "$url" \
            --output "$staged"; then

            echo "ERROR: Failed to download $url" >&2
            failed=1
            cert_failed=1
            continue
        fi

        # Only explicitly configured certificates may have an empty chain file.
        if [ ! -s "$staged" ]; then
            allow_empty=0

            if [ "$file" = "chain.crt" ]; then
                for empty_chain_cert in $EMPTY_CHAIN_CERTS; do
                    if [ "$cert" = "$empty_chain_cert" ]; then
                        allow_empty=1
                        break
                    fi
                done
            fi

            if [ "$allow_empty" -eq 0 ]; then
                echo "ERROR: Downloaded file is empty: $url" >&2
                failed=1
                cert_failed=1
                continue
            fi

            echo "  Empty chain file is valid for $cert"
        fi
    done

    if [ "$cert_failed" -ne 0 ]; then
        continue
    fi

    # nginx expects the server certificate first, followed by its chain.
    if ! {
        cat "$stage_dir/server.crt"
        if [ -s "$stage_dir/chain.crt" ]; then
            printf '\n'
            cat "$stage_dir/chain.crt"
        fi
    } > "$stage_dir/bundle.crt"; then
        echo "ERROR: Failed to build bundle for $cert" >&2
        failed=1
        continue
    fi

    chmod 644 "$stage_dir/server.crt" "$stage_dir/chain.crt" "$stage_dir/bundle.crt"
done

if [ "$failed" -ne 0 ]; then
    echo "One or more certificate downloads or bundles failed."
    echo "Existing certificates were not changed."
    echo "Service will NOT be reloaded."
    failure_message="One or more certificate downloads or bundle builds failed. Existing certificates were not changed and nginx was not reloaded."
    exit 1
fi

# Compare staged files with the installed files.
for cert in $CERTS; do
    cert_changed=0

    for file in server.crt chain.crt bundle.crt; do
        staged="$work_dir/downloads/$cert/$file"
        target="$TARGET_BASE/$cert/$file"

        if [ -f "$target" ] && cmp -s "$staged" "$target"; then
            echo "  $cert/$file unchanged"
        else
            echo "  $cert/$file changed"
            changed=1
            cert_changed=1
        fi
    done

    if [ "$cert_changed" -eq 1 ]; then
        updated_certs="${updated_certs}${updated_certs:+, }$cert"
    fi
done

if [ "$changed" -eq 0 ]; then
    echo "No certificate changes detected."
    exit 0
fi

echo "Certificate changes detected. Installing staged files..."
install_started=1

# Back up and atomically replace only changed files.
for cert in $CERTS; do
    target_dir="$TARGET_BASE/$cert"
    cert_backup_dir="$backup_dir/$cert"

    if ! mkdir -p "$target_dir" "$cert_backup_dir"; then
        echo "ERROR: Could not prepare directories for $cert" >&2
        failure_message="Could not prepare the certificate or backup directories for $cert. Previous files were restored."
        rollback_files
        exit 1
    fi

    for file in server.crt chain.crt bundle.crt; do
        staged="$work_dir/downloads/$cert/$file"
        target="$target_dir/$file"
        backup="$cert_backup_dir/$file"
        marker="$cert_backup_dir/$file.changed"

        if [ -f "$target" ] && cmp -s "$staged" "$target"; then
            continue
        fi

        if [ -e "$target" ] || [ -L "$target" ]; then
            if ! cp -a -- "$target" "$backup"; then
                echo "ERROR: Could not back up $target" >&2
                failure_message="Could not back up $target. Previous certificate files were restored."
                rollback_files
                exit 1
            fi
        fi

        if ! touch "$marker" || ! mv -f -- "$staged" "$target"; then
            echo "ERROR: Could not install $target" >&2
            failure_message="Could not install $target. Previous certificate files were restored."
            rollback_files
            exit 1
        fi
    done
done

echo "Testing nginx configuration..."

if ! nginx -t; then
    echo "ERROR: nginx configuration test failed." >&2
    echo "nginx will NOT be reloaded." >&2
    failure_message="The new certificate files failed the nginx configuration test. Previous certificate files were restored and nginx was not reloaded."
    rollback_files
    exit 1
fi

echo "Reloading nginx..."

if ! $RESTART_CMD; then
    echo "ERROR: nginx reload failed." >&2
    failure_message="nginx failed to reload after installing certificates for: $updated_certs. Previous certificate files were restored."
    rollback_files
    exit 1
fi

update_committed=1
echo "Certificate update completed successfully."
send_notification \
    success \
    "SSL certificates updated" \
    "Updated certificates: $updated_certs. The nginx configuration test passed and nginx was reloaded." || true
exit 0
