locals {
  repositories = {
    for name, options in yamldecode(file("${path.module}/repositories.yaml")) :
    name => merge({ visibility = "public", discussions = false, tier = "push", extra_checks = [] }, options)
  }
  public = { for name, repository in local.repositories : name => repository if repository.visibility == "public" }

  # The listed repositories that already exist on GitHub, which Terraform
  # adopts. A listed repository that does not exist yet is created.
  existing = { for name, repository in local.repositories : name => repository if contains(data.github_repositories.owned.names, name) }
}

# Terraform skips the import of a repository it already holds.
import {
  for_each = local.existing
  to       = github_repository.repository[each.key]
  id       = each.key
}

# Dependabot, secret scanning, and code scanning come from the
# organization's code security configurations, which code-security.sh
# attaches, so this resource leaves them alone.
resource "github_repository" "repository" {
  for_each = local.repositories

  name       = each.key
  visibility = each.value.visibility

  has_issues      = true
  has_discussions = each.value.discussions
  has_projects    = false
  has_wiki        = false

  # main keeps a linear history: a pull request lands as one squashed
  # commit, titled and described by the pull request, or rebased as it is.
  allow_merge_commit          = false
  allow_squash_merge          = true
  allow_rebase_merge          = true
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"
  allow_update_branch         = true
  delete_branch_on_merge      = true

  # Auto-merge waits on a branch's rules, which a private repository on
  # GitHub's Free plan cannot have, so GitHub keeps it off there.
  allow_auto_merge = each.value.visibility == "public"

  # A new repository starts with one commit, so main exists for its ruleset.
  auto_init = true

  # A repository dropped from repositories.yaml is archived, not deleted,
  # and prevent_destroy stops even that until someone removes this line.
  archive_on_destroy = true

  lifecycle {
    prevent_destroy = true
    # A repository's description, homepage, and topics are its own, edited
    # in GitHub, and its Pages site has a resource of its own.
    ignore_changes = [description, homepage_url, topics, pages, has_downloads, auto_init, security_and_analysis]
  }
}

# Every repository that is neither a fork nor archived must be listed, so one
# made outside this file fails the plan until it has an entry and takes the
# standard.
data "github_repositories" "owned" {
  query = "org:liken-sh fork:false archived:false"
}

resource "terraform_data" "every_repository_listed" {
  lifecycle {
    precondition {
      condition     = length(setsubtract(data.github_repositories.owned.names, keys(local.repositories))) == 0
      error_message = "Add these repositories to repositories.yaml: ${join(", ", sort(setsubtract(data.github_repositories.owned.names, keys(local.repositories))))}"
    }
  }
}

# The repositories that code-security.sh and actions.sh read after an
# apply to set what the provider has no resource for.
output "repositories" {
  description = "The listed repositories, which code-security.sh checks"
  value       = sort(keys(local.repositories))
}

output "public_repositories" {
  description = "The public repositories, which actions.sh checks"
  value       = sort(keys(local.public))
}
