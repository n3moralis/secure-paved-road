mock_provider "google" {}

variables {
  project_id = "test-project"
  name       = "test-project-tfstate"
  location   = "europe-west3"
}

# plan only: the bucket has prevent_destroy, so a test apply could not clean up.
run "state_bucket_is_locked_down" {
  command = plan

  assert {
    condition     = google_storage_bucket.this.public_access_prevention == "enforced"
    error_message = "State bucket must never be public."
  }

  assert {
    condition     = google_storage_bucket.this.uniform_bucket_level_access == true
    error_message = "No per-object ACLs on the state bucket."
  }

  assert {
    condition     = google_storage_bucket.this.versioning[0].enabled == true
    error_message = "State history is required for recovery."
  }
}

run "rejects_no_history" {
  command = plan

  variables {
    keep_versions = 0
  }

  expect_failures = [var.keep_versions]
}
