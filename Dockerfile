FROM eclipse-temurin:11-jre

COPY target/hikvision-download-assistant-1.0-SNAPSHOT-jar-with-dependencies.jar /target/hikvision-download-assistant-1.0-SNAPSHOT-jar-with-dependencies.jar
COPY download_video.sh /usr/local/bin/download_video

ENTRYPOINT ["download_video"]