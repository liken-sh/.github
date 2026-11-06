# The provider has no resource for the organization's code security
# configurations, so code-security.sh reads this list after an apply and
# attaches one to each repository that has none.
output "repositories" {
  description = "The listed repositories, which code-security.sh checks"
  value       = sort(keys(local.repositories))
}
