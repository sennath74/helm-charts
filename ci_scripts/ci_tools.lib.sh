#!/usr/bin/env bash
#
# Ping Identity DevOps - CI scripts
#
# Utilities used across all CI scripts
#
test "${VERBOSE}" = "true" && set -x

HISTFILE=~/.bash_history
set -o history
HISTTIMEFORMAT='%T'
export HISTTIMEFORMAT

# get the long tag
_getLongTag() {
    echo "${1}" | awk '{gsub(/[:\/]/,"_");print}'
}

# get the short tag
_getShortTag() {
    echo "${1}" | awk '{gsub(/:.*/,"");print}'
}

###############################################################################
# get_value (variable)
#
# Get the value of a variable passed, preserving any spaces
###############################################################################
get_value() {
    # the following will preserve spaces in the printf
    IFS="%%"
    eval printf '%s' "\${${1}}"
    unset IFS
}

# echos banner bar of 80 hashes '#'
banner_bar() {
    printf '%0.1s' "#"{1..80}
    printf "\n"
}

banner_pad=$(printf '%0.1s' " "{1..80})
# echos banner contents centering argument passed
banner_head() {
    # line is divided like so # <- a -> b <- c ->#
    # b is the string to display centered
    # a and c are whitespace padding to center the string
    _b="${*}"
    if test ${#_b} -gt 78; then
        _a=0
        _c=0
    else
        _a=$(((78 - ${#_b}) / 2))
        _c=$((78 - _a - ${#_b}))
    fi
    printf "#"
    printf '%*.*s' 0 ${_a} "${banner_pad}"
    printf "%s" "${_b}"
    printf '%*.*s' 0 ${_c} "${banner_pad}"
    printf "#\n"
}

# echos full banner with contents
banner() {
    banner_bar
    banner_head "${*}"
    banner_bar
}

FONT_RED="$(printf '\033[0;31m')"
FONT_GREEN="$(printf '\033[0;32m')"
FONT_YELLOW="$(printf '\033[0;33m')"
FONT_NORMAL="$(printf '\033[0m')"
CHAR_CHECKMARK="$(printf '\xE2\x9C\x94')"
CHAR_CROSSMARK="$(printf '\xE2\x9D\x8C')"

################################################################################
# Echo message in red color
################################################################################
echo_red() {
    echo "${FONT_RED}$*${FONT_NORMAL}"
}

################################################################################
# Echo message in yellow color
################################################################################
echo_yellow() {
    echo "${FONT_YELLOW}$*${FONT_NORMAL}"
}

################################################################################
# Echo message in green color
################################################################################
echo_green() {
    echo "${FONT_GREEN}$*${FONT_NORMAL}"
}

################################################################################
# Return input in lowercase
################################################################################
toLower() {
    printf "%s" "${*}" | tr '[:upper:]' '[:lower:]'
}

################################################################################
# append to output following a colorized pattern
################################################################################
append_status() {
    _output="${1}"
    shift
    if test "${1}" = "PASS"; then
        _prefix="${FONT_GREEN}${CHAR_CHECKMARK} "
    else
        _prefix="${FONT_RED}${CHAR_CROSSMARK} "
    fi
    shift
    _pattern="${1}"
    shift
    #As the _pattern and # of inputs is undefined here, it is not easy/reasonable to follow SC2059
    # shellcheck disable=SC2059
    printf "${_prefix}${_pattern}${FONT_NORMAL}\n" "${@}" >> "${_output}"

}

################################################################################
# Convenience function for curl
################################################################################
_curl() {
    curl \
        --get \
        --silent \
        --show-error \
        --location \
        --connect-timeout 2 \
        --retry 6 \
        --retry-max-time 30 \
        --retry-connrefused \
        --retry-delay 3 \
        "${@}"
    return ${?}
}

################################################################################
# Verify that the file is found.  If not, then error/exit
################################################################################
requirePipelineFile() {
    _pipelineFile="$(get_value "${1}")"

    if test ! -f "${_pipelineFile}"; then
        echo_red "${_pipelineFile} file missing. Needs to be defined/created (i.e. ci/cd pipeline file)"
        exit 1
    fi
}

################################################################################
# Verify that the variable is found and not empty.  If not, then error/exit
################################################################################
requirePipelineVar() {
    _pipelineVar="${1}"

    if test -z "${_pipelineVar}"; then
        echo_red "${_pipelineVar} variable missing. Needs to be defined/created (i.e. ci/cd pipeline variable)"
        exit 1
    fi
}