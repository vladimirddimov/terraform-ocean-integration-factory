resource "google_service_account" "ocean_integration_service_account" {
  project      = var.project
  account_id   = var.service_account_id
  display_name = "Ocean Integration Service Account"
}

# resource "google_organization_iam_custom_role" "ocean_integration_iam_org_role" {
#   title       = "Ocean Integration organization role"
#   role_id     = var.role_id
#   permissions = var.permissions
#   org_id      = var.organization
# }

# resource "google_organization_iam_member" "ocean_integration_iam_member" {
#   count  = length(var.projects) == 0 ? 1 : 0
#   org_id = var.organization
#   role   = google_organization_iam_custom_role.ocean_integration_iam_org_role.name
#   member = "serviceAccount:${google_service_account.ocean_integration_service_account.email}"
# }


# resource "google_project_iam_binding" "custom_role_binding" {
#   count = length(var.projects)

#   project = var.projects[count.index]
#   role    = google_organization_iam_custom_role.ocean_integration_iam_org_role.name

#   members = [
#     "serviceAccount:${google_service_account.ocean_integration_service_account.email}"
#   ]
# }
