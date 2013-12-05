#!/bin/bash
echo after success
find . -name .git -prune -o -type f

TARGET=HelloWorld
TAG_NAME=$(date +%F)-${TRAVIS_COMMIT}

(cd build/Release && zip -r9 ${TARGET}.zip ${TARGET}.app)

getreleaseid() {
    if [[ ! -f ./jq ]]; then 
        wget http://stedolan.github.io/jq/download/osx64/jq
        chmod +x jq
    fi
    if [[ ! -f ./releases.json ]]; then
        curl -s "https://api.github.com/repos/${1}/releases" > releases.json
    fi
    ./jq '. | map(select(.tag_name == "'${2}'")) | .[0].id' releases.json
}

RELEASE_ID=$(getreleaseid ${TRAVIS_REPO_SLUG} ${TAG_NAME})
if [ ! "$releaseid" == "null" ]; then
      exit 1
fi

# create release
curl -H "Authorization: token ${TOKEN}" \
     -H "Accept: application/vnd.github.manifold-preview" \
     -X POST \
     -d '{"tag_name":"'${TAG_NAME}'", "target_commitish":"'${TRAVIS_COMMIT}'", "draft":"true"' \
     "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/releases"

RELEASE_ID=$(getreleaseid ${TRAVIS_REPO_SLUG} ${TAG_NAME})
if [ "$releaseid" == "null" ]; then
      exit 1
fi

# upload application.zip
curl -H "Authorization: token ${TOKEN}" \
     -H "Accept: application/vnd.github.manifold-preview" \
     -H "Content-Type: application/zip" \
     --data-binary @build/Release/${TARGET}.zip \
     "https://uploads.github.com/repos/${TRAVIS_REPO_SLUG}/releases/${RELEASE_ID}/assets?name=${TARGET}-${TAG_NAME}.zip"

