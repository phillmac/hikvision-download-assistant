#!/usr/bin/env bash

if [ ! -d output ]
then
    mkdir -v output
fi

cd output

echo '#!/usr/bin/env bash' > ./download.sh
echo 'set -eo pipefail' >> ./download.sh


java -jar ../target/hikvision-download-assistant-1.0-SNAPSHOT-jar-with-dependencies.jar --quiet "${@}"  | grep VIDEO | cut -d '|' -f 5 >> ./download.sh

chmod u+x ./download.sh

./download.sh
