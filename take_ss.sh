#!/bin/bash
set -e

#
# Constants
#
readonly SCRIPT_NAME=$(basename $0)


#
# Usage
#
usage() {
    cat << __EOS__

Usage: ${SCRIPT_NAME} [-o] [-h] [-d] output.gif

Description:
    Take the screen shot.

Options:
    -o  if the output file already exists, then it will be overwrite.
    -h  Show help.
    -d  Debug mode.

__EOS__
}


#
# utils
#
log() { $OPT_DEBUG && echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@"; return 0; }
err() {
    $OPT_DEBUG && echo -n "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: " 1>&2
    echo "Error: $@" 1>&2
}
die() { err $@; usage; exit 1; }



#------------------------------------------------------------------------------
#
#   options / args
#
#------------------------------------------------------------------------------
OPT_DEBUG=false

OPT_PREVENT_OVERWRITE=true
OPT_OUTPUT_PATH=

makeup_output_path() {
    local path="$1"
    local default_file_name="ss-$(date +%FT%T).png"

    if [ -z "${path}" ]; then
        path="$(pwd)/${default_file_name}"

    elif [ -d "${path}" ]; then
        if [ "${path: -1}" = '/' ]; then
            path="${path}${default_file_name}"
        else
            path="${path}/${default_file_name}"
        fi
    fi

    echo "${path}"
}

validate_output_path() {
    if [ -e "${OPT_OUTPUT_PATH}" -a $OPT_PREVENT_OVERWRITE ]; then
        die "error: file exists: ${path}"
    fi
    return 0
}

parse_args() {
    while getopts dh opt; do
        case "${opt}" in
            o ) OPT_PREVENT_OVERWRITE=false ;;
            d ) OPT_DEBUG=true ;;
            h ) usage; exit 0; ;;
            * ) die "invalid option was specified." ;;
        esac
    done
    shift `expr $OPTIND - 1`

    OPT_OUTPUT_PATH=$(makeup_output_path "$1")
    validate_output_path
}



#------------------------------------------------------------------------------
#
#   capture process
#
#------------------------------------------------------------------------------
main() {
    parse_args $@

    log "DEBUG MODE"
    log "Output Path    : ${OPT_OUTPUT_PATH}"

    maim -s ${OPT_OUTPUT_PATH}
}

main $@
exit 0
