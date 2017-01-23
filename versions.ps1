#parse parameters supplied by TeamCity script step
param (
    [string]$branch = "refs/heads/master",
    [string]$branch_is_default = "true",
    [string]$build_number = "0"
)

$is_pull_request = $branch_is_default -ne "true"

# Read major.minor version from version.txt in root of source repo
$txt_version = (Get-Content version.txt | Select-String -pattern '(?<major>[0-9]+)\.(?<minor>[0-9]+)').Matches[0].Groups
$major_version = $txt_version['major'].Value
$minor_version = $txt_version['minor'].Value

# Parse current version number by looking for v1.2.3 tags applied to master branch in Git
(git fetch --tags)
$tags_list = (git tag --sort=v:refname)
$latest_tag = $tags_list.Split([Environment]::NewLine) | Select-Object -Last 1
Write-Host $latest_tag

$matches = Select-String -InputObject $latest_tag -pattern 'v(?<major>[0-9]+)\.(?<minor>[0-9]+).(?<patch>[0-9]+)'

# set major.minor.patch to last tagged version if it exists - otherwise set to 0.0.0
if ($matches.Matches -ne $null -and $matches.Matches.Groups.Count -gt 0) {    
    $git_major_version = $matches.Matches[0].Groups['major'].Value
    $git_minor_version = $matches.Matches[0].Groups['minor'].Value
    $git_patch_version = $matches.Matches[0].Groups['patch'].Value
} else {
    $git_major_version = 0
    $git_minor_version = 0
    $git_patch_version = 0
}

Write-Host "version.txt: $major_version.$minor_version"
Write-Host "Tag version: $git_major_version.$git_minor_version.$git_patch_version"
Write-Host "Pull request: $branch"
Write-Host "Is pull request? $is_pull_request"

$commit_count = (git rev-list "$latest_tag..HEAD" --count)
Write-Host "$commit_count commits to master since $latest_tag"

if ($git_major_version -eq $major_version -and $git_minor_version -eq $minor_version) {
    $patch_version =  [int]$commit_count + [int]$git_patch_version;
} else {
    $patch_version = 0
}
$suffix = ''

if ($is_pull_request) { $suffix = "-pr$branch" }

$vcs_root_labeling_pattern = "v$major_version.$minor_version.$patch_version"
$package_version = [string]::Join('.', @($major_version,	$minor_version, $patch_version, $build_number)) + $suffix
Write-Host "##teamcity[setParameter name='VcsRootLabelingPattern' value='$vcs_root_labeling_pattern']"
Write-Host "##teamcity[setParameter name='PackageVersion' value='$package_version']"
Write-Host "##teamcity[buildNumber '$package_version']"
