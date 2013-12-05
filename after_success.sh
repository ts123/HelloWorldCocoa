#!/bin/sh
echo after success
find . -name .git -prune -o -type f
(cd build/Release && zip -r9 HelloWorld.zip HelloWorld.app)

curl -H "Authorization: token ${TOKEN}" \
     -H "Accept: application/vnd.github.manifold-preview" \
     -X POST \
     -d tag_name=${TRAVIS_BUILD_NUMBER} -d target_commitish=${TRAVIS_COMMIT} -d draft="true" \
     "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/releases/${TRAVIS_BUILD_NUMBER}"

curl -H "Authorization: token ${TOKEN}" \
     -H "Accept: application/vnd.github.manifold-preview" \
     -H "Content-Type: application/zip" \
     --data-binary @build/Release/HelloWorld.zip \
     "https://uploads.github.com/repos/${TRAVIS_REPO_SLUG}/releases/${TRAVIS_BUILD_NUMBER}/assets?name=HelloWorld-${TRAVIS_BUILD_NUMBER}.zip"

