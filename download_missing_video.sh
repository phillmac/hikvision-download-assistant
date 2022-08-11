#!/usr/bin/env bash

if [ ! -d output ]
then
    mkdir -v output
fi

cd output

echo '#!/usr/bin/env bash' > ./download.sh
echo 'set -eo pipefail' >> ./download.sh


java -jar ../target/hikvision-download-assistant-1.0-SNAPSHOT-jar-with-dependencies.jar --quiet --output json  "${@}" | jq -r --compact-output '.results[]' > results.json

while read -r fname curlcmd
    if [[-f "${fname}" ]]
    then
        echo "${curlcmd}" >> ./download.sh
    else
        echo "Skipping already downloaded ${fname}"
    fi
done < <(jq -r . '"\(.outputFilename) \(.curlCommand)"'  < results.json)

chmod u+x ./download.sh

./download.sh
