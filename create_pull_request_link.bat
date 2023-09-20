@ECHO OFF

SET REPOSITORY_NANE=YPLM-YuniquePLM

SET TARGET_BRANCH=develop
IF NOT "%1"=="" SET TARGET_BRANCH=%1

SET CURRENT_BRANCH=
FOR /F %%I IN ('git rev-parse --abbrev-ref HEAD') DO SET CURRENT_BRANCH=%%I

SET LINK=https://us-east-1.console.aws.amazon.com/codesuite/codecommit/repositories/%REPOSITORY_NANE%/pull-requests/new/refs/heads/%TARGET_BRANCH%/.../refs/heads/%CURRENT_BRANCH%

ECHO %LINK% | clip.exe