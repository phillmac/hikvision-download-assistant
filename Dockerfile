FROM eclipse-temurin:11-jre-focal

RUN cp /etc/apt/sources.list /etc/apt/sources.list~ \
  && sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list \
  && apt-get update \
  && apt-get install -y jq unzip build-essential \
  && apt-get build-dep -y curl

COPY curl-7.86.0.zip curl-7.86.0.zip

RUN unzip curl-7.86.0.zip \
  && cd curl-7.86.0 \
  && ./configure --prefix=$HOME/curl --with-openssl \
  && make && make install

COPY live.2023.07.24.tar.gz live.2023.07.24.tar.gz

RUN tar -xzf live.2023.07.24.tar.gz \
  && cd live && ./genMakefiles linux && make && make install

FROM eclipse-temurin:11-jre-focal

ENV PATH="/root/curl/bin:$PATH"

COPY --from=0 /usr/bin/jq /usr/bin/jq
COPY --from=0 /usr/lib/x86_64-linux-gnu/libjq.so.1 /usr/lib/x86_64-linux-gnu/libonig.so.5 /usr/lib/x86_64-linux-gnu/
COPY --from=0 /root/curl/ /root/curl
copy --from=0 /usr/local/bin/openRTSP /usr/local/bin/openRTSP

COPY target/hikvision-download-assistant-1.0-SNAPSHOT-jar-with-dependencies.jar /target/hikvision-download-assistant-1.0-SNAPSHOT-jar-with-dependencies.jar
COPY download_video.sh /usr/local/bin/download_video
COPY download_missing_video.sh /usr/local/bin/download_missing_video
COPY download_missing_events.sh /usr/local/bin/download_missing_events
COPY download_missing_pics.sh /usr/local/bin/download_missing_pics
COPY rtsp_dump.sh /usr/local/bin/rtsp_dump


ENTRYPOINT ["download_missing_video"]