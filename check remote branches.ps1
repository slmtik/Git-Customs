git fetch --all

$branches = git for-each-ref "refs/remotes/origin/" --format="%(refname:lstrip=2)"

git switch master -q

foreach ($branch in $branches)
{
    if (($branch -eq "master") -or ($branch -eq "HEAD"))
    {
        continue
    }

    $sqllFiles = git ls-tree $branch OOTB-Extras/Latest/Reports/SQL.Objects/ --name-only

    foreach($file in $sqllFiles)
    {
        $fileContent = git show $branch":"$file
        $fileContent
        break
    }

    break
}