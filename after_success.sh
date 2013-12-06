#!/bin/bash
echo after success
find . -name .git -prune -o -type f

TARGET_DIR=build/Release
TARGET=HelloWorld
TAG_NAME=$(date +%F)-${TRAVIS_COMMIT:0:7}
echo TAG_NAME:$TAG_NAME

(cd ${TARGET_DIR} && zip -r9 ${TARGET}.zip ${TARGET}.app)

getreleaseid() {
    if [[ ! -f ./jq ]]; then 
        wget http://stedolan.github.io/jq/download/osx64/jq
        chmod +x jq
    fi
    # if [[ ! -f ./releases.json ]]; then
    #     curl -s "https://api.github.com/repos/${1}/releases" > releases.json
    # fi
    curl -s "https://api.github.com/repos/${1}/releases" | ./jq '. | map(select(.tag_name == "'${2}'")) | .[0].id'
}

RELEASE_ID=$(getreleaseid ${TRAVIS_REPO_SLUG} ${TAG_NAME})
if [ ! "$RELEASE_ID" == "null" ]; then
    echo releaseid:$RELEASE_ID exists
    exit 1
fi

# create release
curl -H "Authorization: token ${TOKEN}" \
     -H "Accept: application/vnd.github.manifold-preview" \
     -X POST \
     -d $(printf '{"tag_name":"%s", "target_commitish":"%s", "draft":"true"}' "${TAG_NAME}" "${TRAVIS_COMMIT}") \
     "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/releases"

RELEASE_ID=$(getreleaseid ${TRAVIS_REPO_SLUG} ${TAG_NAME})
if [ "$RELEASE_ID" == "null" ]; then
    echo releaseid:$RELEASE_ID not found
    exit 1
fi

# upload application.zip
curl -H "Authorization: token ${TOKEN}" \
     -H "Accept: application/vnd.github.manifold-preview" \
     -H "Content-Type: application/zip" \
     --data-binary @${TARGET_DIR}/${TARGET}.zip \
     "https://uploads.github.com/repos/${TRAVIS_REPO_SLUG}/releases/${RELEASE_ID}/assets?name=${TARGET}-${TAG_NAME}.zip"

