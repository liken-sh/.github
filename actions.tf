# Each workflow's GITHUB_TOKEN can only read unless the workflow asks for
# more in its own permissions block, and no workflow approves a pull
# request, so a workflow that a pull request changes cannot merge it. The
# organization's setting caps every repository's, so one setting covers
# them all.

import {
  to = github_actions_organization_workflow_permissions.token
  id = "liken-sh"
}

resource "github_actions_organization_workflow_permissions" "token" {
  organization_slug                = "liken-sh"
  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = false
}
