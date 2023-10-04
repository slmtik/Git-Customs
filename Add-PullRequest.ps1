Param(
  $destinationBranch = "develop",
  $sourceCommit = $null
)

try {
    $repositoryName= ([uri](git remote get-url origin)).Segments[-1] 2>$null
}
catch {
    Write-Host "This repository doesn't have remote repository."
    exit 1
}

if ($null -eq $sourceCommit) { $sourceBranches = git branch --show-current }
else 
{
    $sourceBranches = (git show-ref --heads | Select-String "^$sourceCommit refs\/heads\/(?'branchName'\S.+)$") `
        | Select-Object -ExpandProperty Matches `
        | Select-Object @{l="BranchName";e={$_.groups[1].Value}}

    if ($sourceBranches.Length -gt 1)
    {
        for($i = 0; $i -lt ($sourceBranches.Length); $i++)
        {
            $sourceBranches[$i].BranchName >> $pullRequestSelectBranchFile
        }
    }
}

$pullRequestTitle = git log $sourceBranch -1 --pretty=%B | Select-Object -First 1

# git fetch --all

$pullRequestDescription = $null
foreach($line in (git log $sourceBranch --not origin/$destinationBranch --pretty=%B)) {
    if($line -ne $pullRequestTitle){
        $pullRequestDescription += $line + "`n"
    }
}

& $PSScriptRoot/Edit-PullRequestContent.ps1 $destinationBranch $sourceBranches $pullRequestTitle $pullRequestDescription

if (!$pullRequestTitle -or !$pullRequestDescription)
{
    Write-Host "No title and/or description provided. Pull request creation aborted."
    exit 1
}

# https://docs.aws.amazon.com/codecommit/latest/userguide/how-to-create-pull-request.html#how-to-create-pull-request-cli

$pullRequestId = aws codecommit create-pull-request --title $pullRequestTitle --description $pullRequestDescription --targets repositoryName=$repositoryName,sourceReference=$sourceBranch,destinationReference=$destinationBranch --output text --query "pullRequest.pullRequestId"

if (!$pullRequestId) { exit 1 }

$link = "https://us-east-1.console.aws.amazon.com/codesuite/codecommit/repositories/$repositoryName/pull-requests/$pullRequestId"

Start-Process $link