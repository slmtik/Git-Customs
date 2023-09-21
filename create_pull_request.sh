# #!/bin/bash

repositoryName=$(basename $(git remote get-url origin))

[[ "$repositoryName" == "origin" ]] \
    && echo "This repository doesn't have remote repository" \
    && exit 1

sourceBranch=$(git branch --show-current)
destinationBranch="${1:-develop}"

pullRequestTitle=$(git log -1 --pretty=%B | head -1)
pullRequestDescription=

while IFS= read -r line || [ -n "$line" ]
do
    if [[ $line != $pullRequestTitle && ! -z $line ]]
    then 
        pullRequestDescription="$line"$'\n'"$pullRequestDescription"
    fi
done <<< "$(git log $sourceBranch --not origin/$destinationBranch --pretty=%B)"
pullRequestDescription=${pullRequestDescription%$'\n'}

gitDir=$(git rev-parse --git-dir)
pullRequestMessageFile=$gitDir/PULLREQUEST_MSG

echo $pullRequestTitle > $pullRequestMessageFile
    echo "$pullRequestDescription" >> $pullRequestMessageFile
echo \#Please check the title and description for your pull request. >> $pullRequestMessageFile
echo \#First line will be the title, other lines will be description. >> $pullRequestMessageFile
echo \#Lines starting with '#' will be ignored, and an empty file aborts the pull request creation. >> $pullRequestMessageFile

$(git config --get core.editor) $pullRequestMessageFile

firstLineFetched=false
pullRequestDescription=

while IFS= read -r line || [ -n "$line" ]
do
    [[ $line =~ ^#.* ]] && continue
    if [[ $firstLineFetched = false ]]
    then 
        pullRequestTitle="$line"
        firstLineFetched=true
    else
        pullRequestDescription="$pullRequestDescription"$'\n'"$line"
    fi
done < $pullRequestMessageFile

([ -z "$pullRequestTitle" ] || [ -z "$pullRequestDescription" ]) \
    && echo "No title and/or description provided.
Pull request creation aborted" \
    && exit 1

#https://docs.aws.amazon.com/codecommit/latest/userguide/how-to-create-pull-request.html#how-to-create-pull-request-cli

response=$(aws codecommit create-pull-request --title "$pullRequestTitle" --description "$pullRequestDescription" --targets repositoryName=$repositoryName,sourceReference=$sourceBranch,destinationReference=$destinationBranch)

[[ -z "$response" ]] && exit 1

pullRequestId=$(echo "$response" | python -c "import sys, json; print(json.load(sys.stdin)['pullRequest']['pullRequestId'])")

link="https://us-east-1.console.aws.amazon.com/codesuite/codecommit/repositories/YPLM-YuniquePLM/pull-requests/$pullRequestId"

python -m webbrowser $link
