hash="59fff97f7ce1d6ed0b0fa01fa8c858cd5745e840"

editor=$(git config --get core.editor)
gitDir=$(git rev-parse --git-dir)
pullRequestMessageFile=$gitDir/PULLREQUEST_MSG
pullRequestSelectBranchFile=$gitDir/PULLREQUEST_BRANCHES

if [[ -z $1 ]]
then 
    sourceBranch=$(git branch --show-current)
else
    sourceBranch=($(git branch --contains $hash --no-color --format='%(refname:short)'))
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

echo $sourceBranch

