Param(
  $destinationBranch = "develop",
  $sourceCommit = $null
)

$editor = git config --get core.editor
$gitDir = git rev-parse --git-dir
$pullRequestMessageFile=$gitDir + "/PULLREQUEST_MSG"
$pullRequestSelectBranchFile=$gitDir + "/PULLREQUEST_BRANCHES"

$repositoryName=
try {
    $repositoryName= ([uri](git remote get-url origin)).Segments[-1] 2>$null
}
catch {
    Write-Host "This repository doesn't have remote repository."
    exit 1
}

if ($null -eq $sourceCommit) { $sourceBranch = git branch --show-current }
else { $sourceBranch = (git branch --contains $sourceCommit --format='%(refname:short)') -split '\r?\n' }

if ([array]$sourceBranch.Length -gt 1)
{
    $sourceBranch[0] > $pullRequestSelectBranchFile
    for($i = 1; $i -lt ($sourceBranch.Length); $i++)
    {
        $sourceBranch[$i] >> $pullRequestSelectBranchFile
    }
    "#Multiple branches for this commit are detected." >> $pullRequestSelectBranchFile
    "#Please move the desired branch to the first line." >> $pullRequestSelectBranchFile
    "#Lines starting with '#' will be ignored, and an empty file aborts the pull request creation." >> $pullRequestSelectBranchFile

    cmd.exe /c $editor $pullRequestSelectBranchFile

    foreach($line in Get-Content $pullRequestSelectBranchFile) {
        if($line -like '#*'){
            continue
        }
        $sourceBranch = $line
        break
    }
}

$pullRequestTitle = git log -1 --pretty=%B | Select-Object -First 1

# git fetch --all

$pullRequestDescription = $null
foreach($line in (git log $sourceBranch --not origin/$destinationBranch --pretty=%B)) {
    if($line -ne $pullRequestTitle){
        $pullRequestDescription += $line + '\n'
    }
}
$pullRequestDescription = $pullRequestDescription.TrimEnd("\n")

$pullRequestTitle > $pullRequestMessageFile
$pullRequestDescription >> $pullRequestMessageFile
"#Please check the title and description for your pull request." >> $pullRequestMessageFile
"#First line will be the title, other lines will be description." >> $pullRequestMessageFile
"#Lines starting with '#' will be ignored, and an empty file aborts the pull request creation." >> $pullRequestMessageFile

cmd.exe /c $editor $pullRequestMessageFile

$firstLineFetched = $false
$pullRequestDescription = $null

foreach($line in Get-Content $pullRequestMessageFile) {
    if($line -like '#*' -or !$line) { continue }

    if ($firstLineFetched -eq $false)
    {
        $pullRequestTitle = $line
        $firstLineFetched = $true
    }
    else { $pullRequestDescription += $line + '\n' }
}

if (!$pullRequestTitle -or !$pullRequestDescription)
{
    Write-Host "No title and/or description provided. Pull request creation aborted."
    exit 1
}

# https://docs.aws.amazon.com/codecommit/latest/userguide/how-to-create-pull-request.html#how-to-create-pull-request-cli

$response = aws codecommit create-pull-request --title $pullRequestTitle --description $pullRequestDescription --targets repositoryName=$repositoryName,sourceReference=$sourceBranch,destinationReference=$destinationBranch

if (!$response) { exit 1 }

$pullRequestId = (ConvertFrom-Json $response).pullRequest.pullRequestId

$link = "https://us-east-1.console.aws.amazon.com/codesuite/codecommit/repositories/$repositoryName/pull-requests/$pullRequestId"

Start-Process $link