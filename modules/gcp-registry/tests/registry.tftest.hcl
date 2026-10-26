mock_provider "google" {}

variables {
  project_id = "test-project"
  location   = "europe-west3"
}

run "immutable_tags_and_cleanup_by_default" {
  command = apply

  assert {
    condition     = google_artifact_registry_repository.this.docker_config[0].immutable_tags == true
    error_message = "Tags must be immutable by default."
  }

  assert {
    condition     = length(google_artifact_registry_repository.this.cleanup_policies) == 2
    error_message = "Expected keep-recent and age-based cleanup policies."
  }
}

run "age_cleanup_can_be_turned_off" {
  command = apply

  variables {
    delete_older_than_days = null
  }

  assert {
    condition     = length(google_artifact_registry_repository.this.cleanup_policies) == 1
    error_message = "Only keep-recent should remain."
  }
}

run "writers_get_writer_role_only" {
  command = apply

  variables {
    writers = { ci = "serviceAccount:ci@test-project.iam.gserviceaccount.com" }
  }

  assert {
    condition     = google_artifact_registry_repository_iam_member.writers["ci"].role == "roles/artifactregistry.writer"
    error_message = "Writers get roles/artifactregistry.writer, nothing broader."
  }
}
