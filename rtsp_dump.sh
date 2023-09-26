#! /bin/bash

openRTSP \
    -D 10 \
    -c \
    -B 10000000 \
    -b 10000000 \
    -Q \
    -F "${OUTPUT_PREFIX}" \
    -p "${REC_SEG_LEN}" \
    -t \
    -u "${RTSP_USER}" "${RTSP_PASSWD}" \
    "rtsp://${RTSP_HOST}:${RTSP_PORT}/Streaming/Channels/${RTSP_CHAN}"


