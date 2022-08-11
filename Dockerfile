FROM eclipse-temurin:11-jre-focal
RUN apt update && apt install -y jq

FROM eclipse-temurin:11-jre-focal

COPY --from=0 /usr/bin/jq /usr/bin/jq

COPY target/hikvision-download-assistant-1.0-SNAPSHOT-jar-with-dependencies.jar /target/hikvision-download-assistant-1.0-SNAPSHOT-jar-with-dependencies.jar
COPY download_video.sh /usr/local/bin/download_video
COPY  download_missing_video.sh /usr/local/bin/download_missing_video


ENTRYPOINT ["download_missing_video"]