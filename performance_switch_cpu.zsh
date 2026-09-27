#!/usr/bin/env zsh
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: Copyright (c) 2017-2026 Maulik Mistry
#
# ugu - Script to update Ubuntu system and reduce wait.
#
# Author: Maulik Mistry
# Please share support: https://www.paypal.com/paypalme/m1st0
#                       https://venmo.com/code?user_id=3319592654995456106&created=1753283702
#
# For futher system information, see
# `sudo cat /sys/devices/system/cpu/cpu*/cpufreq/*`
#
# This script uses concepts described in:
# Enhanced Intel SpeedStep Technology and Demand-Based Switching on Linux
# Intel Software
# http://software.intel.com/en-us/articles/enhanced-intel-speedstepr-technology-and-demand-based-switching-on-linux/
#
# The current implementation is an independent rewrite and is not copied from
# that article.

# Colorized stdout.
SCRIPT_PATH="${0:A}"
SCRIPT_DIR="${SCRIPT_PATH:h}"
source "${SCRIPT_DIR}/vendor/tput_shell_colorize/tput_shell_colorize.sh"

# Override this in tests; the default is the Linux cpufreq sysfs interface.
CPUFREQ="${CPUFREQ_ROOT:-/sys/devices/system/cpu/cpufreq}"

policy_dirs() {
    local dir
    for dir in "$CPUFREQ"/policy*(N); do
        print -r -- "$dir"
    done
}

show_usage() {
    cat <<EOF
Usage:
  $0 GOVERNOR
  $0 GOVERNOR FREQUENCY_KHZ

Examples:
  $0 performance
  $0 performance 3500000
EOF
}

# Values are combined across all CPU policies. Policies may have different
# individual ranges or governors.
show_summary() {
    local dir
    local current_governor
    local current_min
    local current_max
    local policy_count=0
    local minimum=''
    local maximum=''
    local -a current_governors=()
    local -a available_governors=()
    local -a available_frequencies=()
    typeset -A current_governor_set available_governor_set frequency_set

    for dir in "$CPUFREQ"/policy*(N); do
        (( policy_count++ ))

        if [[ -r "$dir/scaling_available_governors" ]]; then
            available_governors+=( "${(@f)$(< "$dir/scaling_available_governors")}" )
        fi

        if [[ -r "$dir/scaling_governor" ]]; then
            current_governor=$(< "$dir/scaling_governor")
            current_governors+=( "$current_governor" )
        fi

        current_min=$(< "$dir/scaling_min_freq" 2>/dev/null)
        current_max=$(< "$dir/scaling_max_freq" 2>/dev/null)

        if [[ -n "$current_min" ]] &&
           { [[ -z "$minimum" ]] || (( current_min < minimum )); }; then
            minimum="$current_min"
        fi

        if [[ -n "$current_max" ]] &&
           { [[ -z "$maximum" ]] || (( current_max > maximum )); }; then
            maximum="$current_max"
        fi

        if [[ -r "$dir/scaling_available_frequencies" ]]; then
            available_frequencies+=( "${(@f)$(< "$dir/scaling_available_frequencies")}" )
        fi
    done

    if (( policy_count == 0 )); then
        messenger_end "No CPU frequency policies found."
        return 1
    fi

    for current_governor in "${current_governors[@]}"; do
        current_governor_set[$current_governor]=1
    done

    for current_governor in "${available_governors[@]}"; do
        available_governor_set[$current_governor]=1
    done

    local frequency
    for frequency in "${available_frequencies[@]}"; do
        frequency_set[$frequency]=1
    done

    messenger_std "CPU frequency policy summary"
    messenger_std "============================"
    messenger_std "Policies found:       $policy_count"
    messenger_std "Current governors:    ${(j:, :)${(ok)current_governor_set}}"
    messenger_std "Available governors:  ${(j:, :)${(ok)available_governor_set}}"

    if [[ -n "$minimum" && -n "$maximum" ]]; then
        messenger_std "Frequency range:      ${minimum}-${maximum} kHz"
    fi

    if (( ${#frequency_set} > 0 )); then
        messenger_std "Available frequencies: ${(j:, :)${(on)frequency_set}}"
    else
        messenger_std "Available frequencies: not exposed by this driver"
    fi
}

governor_available() {
    local dir="$1"
    local governor="$2"
    local governors

    [[ -r "$dir/scaling_available_governors" ]] || return 1
    governors=$(< "$dir/scaling_available_governors") || return 1

    [[ " $governors " == *" $governor "* ]]
}

validate_governor() {
    local governor="$1"
    local dir
    local failed=0
    local governors

    for dir in "$CPUFREQ"/policy*(N); do
        if ! governor_available "$dir" "$governor"; then
            governors=$(< "$dir/scaling_available_governors")
            messenger_end "Governor '$governor' is not available for $dir."
            messenger_end "Available governors: $governors"
            failed=1
        fi
    done

    (( failed == 0 ))
}

validate_frequency() {
    local frequency="$1"
    local dir
    local minimum
    local maximum

    if [[ "$frequency" != <-> ]]; then
        messenger_end "Invalid frequency '$frequency'."
        messenger_end "The frequency must contain digits only and be specified in kHz."
        return 1
    fi

    for dir in "$CPUFREQ"/policy*(N); do
        if [[ -r "$dir/cpuinfo_min_freq" ]]; then
            minimum=$(< "$dir/cpuinfo_min_freq")
        else
            minimum=$(< "$dir/scaling_min_freq" 2>/dev/null)
        fi

        if [[ -r "$dir/cpuinfo_max_freq" ]]; then
            maximum=$(< "$dir/cpuinfo_max_freq")
        else
            maximum=$(< "$dir/scaling_max_freq" 2>/dev/null)
        fi

        if (( frequency < minimum || frequency > maximum )); then
            messenger_end "Frequency $frequency kHz is outside the valid range for $dir."
            messenger_end "Valid range: $minimum-$maximum kHz."
            return 1
        fi
    done
}

set_governor() {
    local governor="$1"
    local dir
    local current
    local failed=0

    for dir in "$CPUFREQ"/policy*(N); do
        if ! print -r -- "$governor" |
            sudo tee "$dir/scaling_governor" >/dev/null; then
            messenger_end "$dir: failed to set governor"
            failed=1
            continue
        fi

        current=$(< "$dir/scaling_governor" 2>/dev/null)

        if [[ "$current" != "$governor" ]]; then
            messenger_end "$dir: verification failed; current governor is '$current'"
            failed=1
            continue
        fi

        messenger_std "$dir: governor=$current, CPUs=$(< "$dir/affected_cpus")"
    done

    return "$failed"
}

verify_governor() {
    local governor="$1"
    local dir
    local current
    local failed=0

    for dir in "$CPUFREQ"/policy*(N); do
        current=$(< "$dir/scaling_governor" 2>/dev/null)

        if [[ "$current" != "$governor" ]]; then
            messenger_end "$dir: expected '$governor', found '$current'"
            failed=1
        fi
    done

    return "$failed"
}

set_max_frequency() {
    local frequency="$1"
    local dir
    local current
    local failed=0

    for dir in "$CPUFREQ"/policy*(N); do
        if ! print -r -- "$frequency" |
            sudo tee "$dir/scaling_max_freq" >/dev/null; then
            messenger_end "$dir: failed to set maximum frequency"
            failed=1
            continue
        fi

        current=$(< "$dir/scaling_max_freq" 2>/dev/null)

        if [[ "$current" != "$frequency" ]]; then
            messenger_end "$dir: verification failed; current maximum is ${current} kHz"
            failed=1
            continue
        fi

        messenger_std "$dir: maximum frequency=$current kHz, CPUs=$(< "$dir/affected_cpus")"
    done

    return "$failed"
}

if [[ ! -d "$CPUFREQ" ]]; then
    messenger_end "CPU frequency policy interface was not found: $CPUFREQ"
    exit 1
fi

case "$#" in
    0)
        show_usage
        linefeed
        show_summary
        exit $?
        ;;

    1)
        governor="$1"
        frequency=""
        ;;

    2)
        governor="$1"
        frequency="$2"
        ;;

    *)
        messenger_end "Error: expected zero, one, or two arguments."
        linefeed
        show_usage >&2
        exit 1
        ;;
esac

if ! validate_governor "$governor"; then
    linefeed
    messenger_end "The requested governor is not available."
    linefeed
    show_summary
    exit 1
fi

if [[ -n "$frequency" ]] && ! validate_frequency "$frequency"; then
    linefeed
    messenger_end "The requested frequency is invalid."
    linefeed
    show_summary
    exit 1
fi

set_governor "$governor" || exit 1

if [[ -n "$frequency" ]]; then
    set_max_frequency "$frequency" || exit 1
fi
