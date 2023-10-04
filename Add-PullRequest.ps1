Param(
  $destinationBranch = "develop",
  $sourceCommit = $null
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

try {
    $repositoryName= ([uri](git remote get-url origin)).Segments[-1] 2>$null
}
catch {
    Write-Host "This repository doesn't have remote repository."
    exit 1
}

$sourceBranches = @()
if ($null -eq $sourceCommit) { $sourceBranches += (git branch --show-current) }
else 
{
    $sourceBranches += (git show-ref --heads | Select-String "^$sourceCommit refs\/heads\/(?'branchName'\S.+)$") `
        | Select-Object -ExpandProperty Matches `
        | Select-Object @{l="BranchName";e={$_.groups[1].Value}} `
        | ForEach-Object {$_.BranchName}
}

$pullRequestTitle = git log $sourceBranches[0] -1 --pretty=%B | Select-Object -First 1

# git fetch --all

$pullRequestDescription = $null
$firstLine = $true
foreach($line in (git log $sourceBranches[0] --not origin/$destinationBranch --pretty=%B)) {
    if($line -ne $pullRequestTitle){
        $pullRequestDescription += $line
        if (!$first){
            $pullRequestDescription += "`r`n"
        }
        else {
            $first = $false
        }
    }
}

$pullRequestData = & $PSScriptRoot/Edit-PullRequestContent.ps1 $destinationBranch $sourceBranches $pullRequestTitle $pullRequestDescription

if (!$pullRequestData.Title -or !$pullRequestData.Description)
{
    Write-Host "Pull request creation was aborted or title and/or description weren't provided."
    exit 1
}

# https://docs.aws.amazon.com/codecommit/latest/userguide/how-to-create-pull-request.html#how-to-create-pull-request-cli

$pullRequestId = aws codecommit create-pull-request --title $pullRequestData.Title --description $pullRequestData.Description --targets repositoryName=$repositoryName,sourceReference="$($pullRequestData.SourceBranch)",destinationReference=$destinationBranch --output text --query "pullRequest.pullRequestId"

if (!$pullRequestId) { exit 1 }

$link = "https://us-east-1.console.aws.amazon.com/codesuite/codecommit/repositories/$repositoryName/pull-requests/$pullRequestId"

Start-Process $link