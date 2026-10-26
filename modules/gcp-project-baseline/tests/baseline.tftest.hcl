# Runs with a mocked provider: no cloud account, no cost, seconds per run.
mock_provider "google" {}

variables {
  project_id = "test-project"
}

run "defaults_turn_on_data_access_audit_logs" {
  command = apply

  assert {
    condition     = length(google_project_iam_audit_config.data_access) == 2
    error_message = "Data Access audit logs must be on for storage and registry by default."
  }

  assert {
    condition     = contains(output.enabled_services, "sts.googleapis.com")
    error_message = "STS (keyless CI token exchange) must be enabled by default."
  }
}

run "budget_alerts_include_forecast" {
  command = apply

  variables {
    budget = {
      billing_account = "000000-000000-000000"
      amount          = 20
    }
  }

  assert {
    condition     = length(google_billing_budget.this[0].threshold_rules) == 4
    error_message = "Expected 3 actual-spend thresholds plus 1 forecast alert."
  }
}

run "rejects_zero_budget" {
  command = plan

  variables {
    budget = {
      billing_account = "000000-000000-000000"
      amount          = 0
    }
  }

  expect_failures = [var.budget]
}
