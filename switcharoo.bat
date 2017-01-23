git checkout master
git branch -D pr%1
git fetch
git pull
git fetch --tags
git fetch origin refs/pull/%1/merge:pr%1
git checkout pr%1
powershell .\versions.ps1
