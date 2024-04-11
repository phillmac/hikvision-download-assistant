#!/usr/bin/env bash

output_dir=${OUTPUT_DIR:-'/output'}

if [[ ! -d "${output_dir}/tmp" ]]
then
    mkdir -pv "${output_dir}/tmp"
fi

cd "${output_dir}/tmp" || exit

echo '#!/usr/bin/env bash' > ./download.sh
echo 'set -eo pipefail' >> ./download.sh

failed=0

if ! java -jar /target/hikvision-download-assistant-1.0-SNAPSHOT-jar-with-dependencies.jar --quiet --output json  "${@}" > output.json
then
    echo "$(date) ~ Failed to search for assets"
    failed=1
fi

if ! ((failed))
then
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
            if [[ -f "${output_dir}/${fname}" ]]
            then
                echo "Skipping already downloaded ${fname}"
            else
                echo 'echo "$(date) Fetching '"${fname}"' ['${pcount}'/${fcount}/${tcount}]" | tee progress.log.txt' >> ./download.sh.tmp
                echo "${curlcmd}" '2> >(tee curl.log.txt >&2)' >> ./download.sh.tmp
                echo "mv -v '${output_dir}/tmp/${fname}' '${output_dir}'" >> ./download.sh.tmp
                ((pcount=pcount+1))
            fi
        fi
    done < <(jq -r  '. | "\(.mediaType) \(.outputFilename) \(.curlCommand)"'  < results.json)

    if ((tcount < 1))
    then
        echo "$(date) ~ Failed to find any assets"
        failed=1
    fi

    echo "tcount=${tcount}" >> ./download.sh
    echo "fcount=$((pcount - 1 ))" >> ./download.sh

    cat ./download.sh.tmp >> ./download.sh

    chmod u+x ./download.sh

    if ! ./download.sh
    then
        echo "Download failed"
        failed=255
    fi

fi

cd / && rm -rvf "${output_dir}/tmp"

if ((failed))
then
    exit ${failed}
fi
