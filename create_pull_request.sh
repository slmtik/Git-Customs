# #!/bin/bash

editor=$(git config --get core.editor)
gitDir=$(git rev-parse --git-dir)
pullRequestMessageFile=$gitDir/PULLREQUEST_MSG
pullRequestSelectBranchFile=$gitDir/PULLREQUEST_BRANCHES

repositoryName=$(basename $(git remote get-url origin))

[[ "$repositoryName" == "origin" ]] \
    && echo "This repository doesn't have remote repository" \
    && exit 1

destinationBranch="${1:-develop}"

if [[ -z $2 ]]
then 
    sourceBranch=$(git branch --show-current)
else
    sourceBranch=($(git branch --contains $2 --format='%(refname:short)'))
fi

if [[ ${#sourceBranch[@]} -gt 1 ]]
then
    echo ${sourceBranch[0]} > $pullRequestSelectBranchFile
    for branch in ${sourceBranch[@]:1} 
    do
        echo $branch >> $pullRequestSelectBranchFile
    done
    echo \#Multiple branches for this commit are detected. >> $pullRequestSelectBranchFile
    echo \#Please move the desired branch to the first line. >> $pullRequestSelectBranchFile
    echo \#Lines starting with '#' will be ignored, and an empty file aborts the pull request creation. >> $pullRequestSelectBranchFile

    $editor $pullRequestSelectBranchFile

    while IFS= read -r line || [ -n "$line" ]
    do
        [[ $line =~ ^#.* ]] && continue
        sourceBranch=$line
    done < $pullRequestSelectBranchFile
fi

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

echo $pullRequestTitle > $pullRequestMessageFile
echo "$pullRequestDescription" >> $pullRequestMessageFile
echo \#Please check the title and description for your pull request. >> $pullRequestMessageFile
echo \#First line will be the title, other lines will be description. >> $pullRequestMessageFile
echo \#Lines starting with '#' will be ignored, and an empty file aborts the pull request creation. >> $pullRequestMessageFile

$editor $pullRequestMessageFile

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
        [[ -z $line ]] && continue
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
