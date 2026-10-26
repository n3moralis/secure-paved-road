resource "google_project_service" "this" {
  for_each = var.services

  project = var.project_id
  service = each.value
  # Other blocks may still depend on an API when this one is removed.
  disable_on_destroy = false
}

data "google_project" "this" {
  project_id = var.project_id
}

resource "google_billing_budget" "this" {
  count = var.budget == null ? 0 : 1

  billing_account = var.budget.billing_account
  display_name    = var.budget.display_name

  budget_filter {
    projects = ["projects/${data.google_project.this.number}"]
  }

  amount {
    specified_amount {
      # currency_code omitted: must equal the billing account's currency
      units = tostring(var.budget.amount)
    }
  }

  dynamic "threshold_rules" {
    for_each = var.budget.thresholds
    content {
      threshold_percent = threshold_rules.value
    }
  }

  dynamic "threshold_rules" {
    for_each = var.budget.forecast_alert ? [1] : []
    content {
      threshold_percent = 1.0
      spend_basis       = "FORECASTED_SPEND"
    }
  }

  depends_on = [google_project_service.this]
}

resource "google_project_iam_audit_config" "data_access" {
  for_each = var.data_access_audit_services

  project = var.project_id
  service = each.value

  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}
