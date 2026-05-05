#!/bin/bash

FILE="/opt/ohpc/pub/apps/spack/1.1.1/etc/spack/site/packages.yaml"
LOG_INFO="\e[32m[INFO]\e[0m"
LOG_WARN="\e[33m[WARN]\e[0m"

echo -e "$LOG_INFO Starting Spack/Module sync..."

# 1. Get modules
for mod in $(module -t avail 2>&1 | grep -v ':$' | grep -v '^$'); do

    # 2. Extract and CLEAN the Prefix
    # We grep for the path, then use sed to strip out Lmod metadata (commas, braces, etc.)
    PREFIX=$(module show "$mod" 2>&1 | grep -oP '/opt/ohpc/\S+' | sed 's/[,{}":].*//' | sed 's/\/bin$//; s/\/lib64$//; s/\/lib$//; s/\/include$//' | sort -u | head -n 1)

    if [[ -z "$PREFIX" ]]; then
        continue
    fi

    # 3. Check for exact match in YAML
    # Using strenv for safety against any weird characters
    MATCH=$(MOD_PATH="$PREFIX" yq '.packages.[].externals[] | select(.prefix == strenv(MOD_PATH)) | .prefix' "$FILE")

    if [[ -n "$MATCH" ]]; then
        echo -e "$LOG_INFO \e[32mMatch!\e[0m $mod -> $PREFIX"

        MOD_NAME="$mod" MOD_PATH="$PREFIX" yq -i '
          .packages.[].externals[] |=
          select(.prefix == strenv(MOD_PATH)) .modules = [strenv(MOD_NAME)]
        ' "$FILE"
    else
        # Log this so you can see the cleaned path that failed to match
        echo -e "  $LOG_WARN No match in YAML for cleaned path: $PREFIX"
    fi
done
