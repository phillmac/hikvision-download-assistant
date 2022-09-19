#!/usr/bin/env bash

if [ ! -d output ]
then
    mkdir -v output
fi

cd output || exit

echo '#!/usr/bin/env bash' > ./download.sh
echo 'set -eo pipefail' >> ./download.sh


java -jar ../target/hikvision-download-assistant-1.0-SNAPSHOT-jar-with-dependencies.jar --quiet --output json  "${@}" > output.json
cat output.json | jq -r --compact-output '.results[]' > results.json

while read -r mediatype fname curlcmd
do
    if [[ "${mediatype}" == "PHOTO" ]]
    then
        echo "Checking ${fname}"
        if [[ -f "${fname}" ]]
        then
            echo "Skipping already downloaded ${fname}"
        else
            echo "${curlcmd}" >> ./download.sh
        fi
    fi
done < <(jq -r  '. | "\(.mediaType) \(.outputFilename) \(.curlCommand)"'  < results.json)

chmod u+x ./download.sh

./download.sh
