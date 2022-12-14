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
((fcount=0))
((pcount=1))
echo '' >> ./download.sh.tmp

while read -r mediatype fname curlcmd
do
    if [[ "${mediatype}" == "VIDEO" ]]
    then
        ((fcount=fcount+1))
        echo "Checking ${fname} [${fcount}]"
        if [[ -f "${fname}" ]]
        then
            echo "Skipping already downloaded ${fname}"
        else
            echo 'echo "$(date) Fetching '"${fname}"' ['${pcount}'/${fcount}]"' >> ./download.sh.tmp
            echo "${curlcmd}" '2> curl.log' >> ./download.sh.tmp
            ((pcount=pcount+1))
        fi
    fi
done < <(jq -r  '. | "\(.mediaType) \(.outputFilename) \(.curlCommand)"'  < results.json)

echo "fcount=${fcount}" >> ./download.sh
cat ./download.sh.tmp >> ./download.sh

chmod u+x ./download.sh

./download.sh
