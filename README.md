# liken-sh/.github

The organization's profile, in [`profile/`](profile/README.md), and the
settings of every repository under github.com/liken-sh that is neither a
fork nor archived, managed with Terraform.

[`repositories.yaml`](repositories.yaml) lists the repositories and what
each one sets beyond the standard.  The standard is:

- Pull requests merge by squash, titled and described by the pull request,
  or by rebase, and never with a merge commit.  A merged branch is deleted.
- main keeps a linear history that no one force-pushes or deletes.  A
  repository in the `pr` tier also takes changes only through a pull
  request whose `All checks passed` job succeeded.
- One of the organization's code security configurations covers each
  repository: "GitHub recommended", or "Github recommended with custom
  code scanning" for a repository that runs CodeQL from a workflow of its
  own.  The configurations themselves are edited in the organization's
  settings.

The organization is on GitHub's Free plan, which has no organization
rulesets, so each public repository has a ruleset of its own, and a
private repository has none.

## Applying

The state is in a Linode Object Storage bucket, read with the key in the
1Password item "GitHub Settings State - liken-sh" (see `backend.tf`).  The
token is in the 1Password item "GitHub Terraform - liken-sh".

```
export AWS_ACCESS_KEY_ID=…      # the state item's username
export AWS_SECRET_ACCESS_KEY=…  # the state item's password
export GITHUB_TOKEN=…           # the token item's credential
terraform plan
terraform apply
GH_TOKEN=$GITHUB_TOKEN ./code-security.sh          # report each repository with no configuration
GH_TOKEN=$GITHUB_TOKEN ./code-security.sh --apply  # and attach one
```

A new entry in `repositories.yaml` creates its repository.  An entry for
a repository that already exists adopts it by import, and the plan fails
when GitHub has a repository that the file does not list.  Terraform
archives rather than deletes a repository dropped from the list.

## CI

A pull request plans, and a push to main applies and attaches a code
security configuration to any repository that has none.  A daily run
fails when its plan has any change in it or a repository has no
configuration, which catches a setting changed by hand, an unlisted
repository, and an expired token.  The workflow's secrets are
`SETTINGS_TOKEN`, a fine-grained token with Administration read and write
and Contents read on every repository and Administration read and write on
the organization, and `STATE_ACCESS_KEY_ID` and `STATE_SECRET_ACCESS_KEY`,
from the 1Password items.
