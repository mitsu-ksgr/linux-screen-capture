#!/bin/bash
set -e

#
# Constants
#
readonly SCRIPT_NAME=$(basename $0)
readonly DEFAULT_REC_TIME=7


#
# Usage
#
usage() {
    cat << __EOS__

Usage: ${SCRIPT_NAME} [-t REC_TIME] [-o] [-h] [-d] output.gif

Description:
    Record the screen.

Options:
    -t  Recording time [sec]. default ${DEFAULT_REC_TIME} sec.
    -o  if the output file already exists, then it will be overwrite.
    -h  Show help.
    -d  Debug mode.

__EOS__
}


#
# Prepare temp dir
#
unset TMP_DIR
on_exit() { [[ -n "${TMP_DIR}" ]] && rm -rf "${TMP_DIR}"; }
trap on_exit EXIT
trap 'trap - EXIT; on_exit; exit -1' INT PIPE TERM
readonly TMP_DIR=$(mktemp -d "/tmp/${SCRIPT_NAME}.tmp.XXXXXX")


#
# utils
#
log() { $OPT_DEBUG && echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@"; return 0; }
err() {
    $OPT_DEBUG && echo -n "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: " 1>&2
    echo "Error: $@" 1>&2
}
die() { err $@; usage; exit 1; }

get_ext() {
    local f=$1
    local ext="${f##*.}"
    [ "${f}" == "${ext}" ] && echo '' || echo "${ext}"
}



#------------------------------------------------------------------------------
#
#   options / args
#
#------------------------------------------------------------------------------
OPT_DEBUG=false

OPT_REC_TIME=${DEFAULT_REC_TIME}
OPT_REC_FRAMERATE=24

OPT_OUTPUT_PATH=
OPT_OUTPUT_FORMAT=

makeup_output_path() {
    local path="$1"
    local default_file_name="ss-$(date +%FT%T).gif"

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

validate_format() {
    case "${OPT_OUTPUT_FORMAT}" in
        gif | mp4 )
            return 0
            ;;
        * )
            die "invalid format: ${OPT_OUTPUT_FORMAT}"
            ;;
    esac
}

validate_output_path() {
    if [ -e "${OPT_OUTPUT_PATH}" -a $OPT_PREVENT_OVERWRITE ]; then
        die "error: file exists: ${path}"
    fi
    return 0
}

parse_args() {
    while getopts t:dh opt; do
        case "${opt}" in
            t ) OPT_REC_TIME=${OPTARG} ;;
            d ) OPT_DEBUG=true ;;
            h ) usage; exit 0; ;;
            * ) die "invalid option was specified." ;;
        esac
    done
    shift `expr $OPTIND - 1`

    OPT_OUTPUT_PATH=$(makeup_output_path "$1")
    OPT_OUTPUT_FORMAT=$(get_ext "${OPT_OUTPUT_PATH}")

    validate_format
    validate_output_path
}



#------------------------------------------------------------------------------
#
#   capture process
#
#------------------------------------------------------------------------------
output_gif() {
    # cf. https://craftzdog.hateblo.jp/entry/generating-a-beautiful-gif-from-a-video-with-ffmpeg

    local mp4_path=${1}
    local output_file_path=${2}
    local pallet_path="${TMP_DIR}/pallet.png"

    # 1. generate pallet image
    ffmpeg -i ${mp4_path} -vf "palettegen" -y ${pallet_path}

    # 2. make gif with the pallet image
    ffmpeg \
        -i ${mp4_path} -i ${pallet_path} \
        -lavfi "fps=12,scale=900:-1:flags=lanczos [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
        -y ${output_file_path}
}

output_mp4() {
    local mp4_path=${1}
    local output_file_path=${2}
    cp ${mp4_path} ${output_file_path}
}

main() {
    parse_args $@

    log "Debug Mode     : ${OPT_DEBUG}"
    log "RecTime        : ${OPT_REC_TIME}"
    log "Output Path    : ${OPT_OUTPUT_PATH}"
    log "Output Format  : ${OPT_OUTPUT_FORMAT}"
    log "Temp Dir       : ${TMP_DIR}"

    # Select capture range
    local slop_result=$(slop -f "%x %y %w %h") || exit 1
    local x y w h
    read -r x y w h < <(echo $slop_result)
    log "Slop           : ($x, $y) $w x $h"

    # capture with ffmpeg
    # Note: ffmpeg option
    #   -r ... フレームレート
    #   -t ... 指定秒数だけ変換
    #   -q:v ... 画質, 0 ~ 32 を指定する, 値が低いほど高画質
    #   -q:a ... https://trac.ffmpeg.org/wiki/Encode/MP3
    local tmp_mp4_path="${TMP_DIR}/cap.mp4"
    ffmpeg -y \
        -f x11grab \
        -r ${OPT_REC_FRAMERATE} \
        -t ${OPT_REC_TIME} \
        -s "$w"x"$h" -i :0.0+$x,$y \
        -q:v 0 -q:a 0 \
        ${tmp_mp4_path}

    # genenrate output file
    case "${OPT_OUTPUT_FORMAT}" in
        gif ) output_gif "${tmp_mp4_path}" "${OPT_OUTPUT_PATH}" ;;
        mp4 ) output_mp4 "${tmp_mp4_path}" "${OPT_OUTPUT_PATH}" ;;
    esac
}


main $@
exit 0
