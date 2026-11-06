# liken-sh/.github

The organization's profile, in [`profile/`](profile/README.md), and the
settings of every repository under github.com/liken-sh that is neither a
fork nor archived, managed with Terraform.

[`repositories.yaml`](repositories.yaml) lists the repositories and what
each one sets beyond the standard.  The standard is:

- Pull requests merge by squash, titled and described by the pull request,
  or by rebase, and never with a merge commit.  A merged branch is deleted.
- A workflow's `GITHUB_TOKEN` only reads unless the workflow asks for
  more, and no workflow approves a pull request.  A pull request from a
  fork by someone who has never contributed waits for approval before its
  workflows run.
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

The state is in a Linode Object Storage bucket (see `backend.tf`).

```
export AWS_ACCESS_KEY_ID=…      # the bucket's access key ID
export AWS_SECRET_ACCESS_KEY=…  # and its secret
export GITHUB_TOKEN=…           # a token with SETTINGS_TOKEN's access (see CI)
terraform plan
terraform apply
GH_TOKEN=$GITHUB_TOKEN ./code-security.sh          # report each repository with no configuration
GH_TOKEN=$GITHUB_TOKEN ./code-security.sh --apply  # and attach one
GH_TOKEN=$GITHUB_TOKEN ./actions.sh                # report where forks' pull requests run without approval
GH_TOKEN=$GITHUB_TOKEN ./actions.sh --apply        # and require it
```

A new entry in `repositories.yaml` creates its repository.  An entry for
a repository that already exists adopts it by import, and the plan fails
when GitHub has a repository that the file does not list.  Terraform
archives rather than deletes a repository dropped from the list.

## CI

A pull request plans, and a push to main applies, attaches a code
security configuration to any repository that has none, and requires
approval for forks' pull requests where it is not required.  A daily run
fails when its plan has any change in it, or when either script finds
something to change, which catches a setting changed by hand, an unlisted
repository, and an expired token.  The workflow's secrets are
`SETTINGS_TOKEN`, a fine-grained token with Administration read and write
and Contents read on every repository and Administration read and write on
the organization, and `STATE_ACCESS_KEY_ID` and `STATE_SECRET_ACCESS_KEY`,
the bucket's access key.
