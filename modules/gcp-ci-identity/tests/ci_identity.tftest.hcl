# The mock invents random strings for computed attributes; the provider then
# rejects them where it validates a format (service_account_id must be a full
# resource name). Give the computed attributes realistic shapes.
mock_provider "google" {
  mock_resource "google_service_account" {
    defaults = {
      name  = "projects/test-project/serviceAccounts/ci-publisher@test-project.iam.gserviceaccount.com"
      email = "ci-publisher@test-project.iam.gserviceaccount.com"
    }
  }

  mock_resource "google_iam_workload_identity_pool" {
    defaults = {
      name = "projects/123456789012/locations/global/workloadIdentityPools/github"
    }
  }
}

variables {
  project_id    = "test-project"
  repository    = "owner/repo"
  repository_id = "123456"
}

run "publisher_only_from_main_of_this_repo" {
  command = apply

  assert {
    condition     = google_iam_workload_identity_pool_provider.this.attribute_condition == "assertion.repository_id == '123456'"
    error_message = "Provider must accept tokens from this repository ID only."
  }

  assert {
    condition     = length(google_service_account_iam_member.wif) == 1
    error_message = "Default is exactly one binding: publisher from main."
  }

  assert {
    condition     = endswith(google_service_account_iam_member.wif["ci-publisher|refs/heads/main"].member, "/attribute.repo_ref/123456:refs/heads/main")
    error_message = "Publisher must be bound to repository ID + refs/heads/main."
  }
}

run "release_identity_from_a_tag" {
  command = apply

  variables {
    service_accounts = {
      "ci-release" = {
        display_name = "release"
        allowed_refs = ["refs/tags/v1.0.0"]
      }
    }
  }

  assert {
    condition     = endswith(google_service_account_iam_member.wif["ci-release|refs/tags/v1.0.0"].member, ":refs/tags/v1.0.0")
    error_message = "Custom identities must be bound to their exact refs."
  }
}

run "rejects_repository_name_instead_of_id" {
  command = plan

  variables {
    repository_id = "owner/repo"
  }

  expect_failures = [var.repository_id]
}

run "rejects_wildcard_refs" {
  command = plan

  variables {
    service_accounts = {
      "ci-publisher" = {
        display_name = "publisher"
        allowed_refs = ["refs/heads/*"]
      }
    }
  }

  expect_failures = [var.service_accounts]
}
