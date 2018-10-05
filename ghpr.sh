#!/bin/bash
file=".ghpr"
if vim -c 'startinsert' $file && [[ -s $file ]]; then
    body=$(< $file)
else
    echo "No pull request description"
    exit 1
fi
rm -f $file

branch=$(git rev-parse --abbrev-ref HEAD)

echo -n "Pushing branch..."
git push origin $branch &> /dev/null
if [ $? -gt 0 ]; then
    echo "Unable to push branch"
    exit 1
fi
echo "done"

origin=$(git config --get remote.origin.url)
[[ $origin =~ :([A-Za-z]*)/([A-Za-z]*).git$ ]]
org=${BASH_REMATCH[1]}
repo=${BASH_REMATCH[2]}
url="https://api.github.com/repos/$org/$repo/pulls?access_token=$GITHUB_TOKEN"

if ! [[ $branch =~ ^([A-Za-z0-9-]*)-([A-Za-z0-9]*)$ ]]; then
    echo "Invalid branch name"
    exit 1
fi
name=$(echo ${BASH_REMATCH[1]} | sed 's/-/ /g')
name=$(echo $name | awk '{for (i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
tag=${BASH_REMATCH[2]}
if [ ${#tag} -gt 3 ]; then
    tag="cur"
fi
title="[$tag] $name"

head="$org:$branch"

json="{\"title\":\"$title\",\"head\":\"$head\",\"body\":\"$body\",\"base\":\"master\"}"

header="Content-Type: application/json"

echo -n "Opening pull request..."
res=$(curl -s -o /dev/null -w '%{http_code}\n' -H "$header" -X POST -d "$json" "$url")
if [ $res -ge 300 ]; then
    echo "Unable to open pull request"
    exit 1
fi
echo "done"
