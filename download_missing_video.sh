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
((pcount=1))
((tcount=0))
echo '' > ./download.sh.tmp

while read -r mediatype fname curlcmd
do
    if [[ "${mediatype}" == "VIDEO" ]]
    then
        ((tcount=tcount+1))
        echo "Checking ${fname} [${tcount}]"
        if [[ -f "${fname}" ]]
        then
            echo "Skipping already downloaded ${fname}"
        else
            echo 'echo "$(date) Fetching '"${fname}"' ['${pcount}'/${fcount}/${tcount}]" | tee progress.log.txt' >> ./download.sh.tmp
            echo "${curlcmd}" '2> >(tee curl.log.txt >&2)' >> ./download.sh.tmp
            ((pcount=pcount+1))
        fi
    fi
done < <(jq -r  '. | "\(.mediaType) \(.outputFilename) \(.curlCommand)"'  < results.json)

echo "tcount=${tcount}" >> ./download.sh
echo "fcount=$((pcount - 1 ))" >> ./download.sh

cat ./download.sh.tmp >> ./download.sh

chmod u+x ./download.sh

./download.sh
