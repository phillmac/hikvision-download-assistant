#! /bin/bash

DTNOW=$(date '+%F_%T')

openRTSP \
    -D 10 \
    -d "{$MAX_DURATION:-86400}" \
    -c \
    -B 10000000 \
    -b 10000000 \
    -Q \
    -F "${OUTPUT_PREFIX}_${DTNOW}_" \
    -P "${REC_SEG_LEN}" \
    -t \
    -u "${RTSP_USER}" "${RTSP_PASSWD}" \
    "rtsp://${RTSP_HOST}:${RTSP_PORT}/Streaming/Channels/${RTSP_CHAN}"


