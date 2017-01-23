$branch_name = (git rev-parse --abbrev-ref HEAD)

$now = ([DateTime]::Now).ToString("O")

echo "$branch_name - changed at $now" >> "$branch_name.txt"

git add "$branch_name.txt" 2>&1
git commit -m "$branch_name edited $branch_name.txt at $now" 2>&1
git push 2>&1

  