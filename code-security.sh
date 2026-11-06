#!/usr/bin/env bash
# Reports each repository that no code security configuration covers, and
# with --apply, attaches one. A repository that runs CodeQL from a workflow
# of its own, as one whose code must be built while CodeQL watches does,
# gets "Github recommended with custom code scanning", which leaves code
# scanning to that workflow. Every other repository gets "GitHub
# recommended". A repository already covered keeps its configuration, so
# one attached by hand stays as it is.
#
#   ./code-security.sh [--apply]
#
# It reads Terraform's repositories output, so it needs the state of an
# apply, and gh signed in with organization Administration write.

set -euo pipefail
cd "$(dirname "$0")"

org=liken-sh
apply=false
[ "${1:-}" = --apply ] && apply=true

configuration() {
    gh api "orgs/$org/code-security/configurations" --jq ".[] | select(.name == \"$1\") | .id"
}

# Whether a workflow of the repository's own runs CodeQL's analysis.
scans_itself() {
    local paths path
    # A repository with no workflows answers 404, and so has none of its own.
    paths=$(gh api "repos/$org/$1/contents/.github/workflows" --jq '.[].path' 2>/dev/null) || return 1
    for path in $paths; do
        if gh api "repos/$org/$1/contents/$path" -H "Accept: application/vnd.github.raw" |
            grep -q 'github/codeql-action/analyze'; then
            return 0
        fi
    done
    return 1
}

uncovered=0
for repository in $(terraform output -json repositories | jq -r '.[]'); do
    # A repository with no configuration answers 204 with no body.
    attached=$(gh api "repos/$org/$repository/code-security-configuration" --jq '.configuration.name // empty')
    [ -n "$attached" ] && continue
    uncovered=$((uncovered + 1))
    if ! $apply; then
        echo "$repository: no code security configuration"
        continue
    fi
    if scans_itself "$repository"; then
        name="Github recommended with custom code scanning"
    else
        name="GitHub recommended"
    fi
    gh api --silent -X POST "orgs/$org/code-security/configurations/$(configuration "$name")/attach" \
        -f scope=selected -F "selected_repository_ids[]=$(gh api "repos/$org/$repository" --jq .id)"
    echo "$repository: attached $name"
done

# A report that finds a repository uncovered fails, so a scheduled run says so.
$apply || [ "$uncovered" -eq 0 ]
