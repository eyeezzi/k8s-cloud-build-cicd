# A bucket to store Terraform state
resource "google_storage_bucket" "terraform-state-4e60ea1a1007" {
  name = "terraform-state-4e60ea1a1007"
  versioning {
    enabled = true
  }
}

# Allow the DigitalOcean cluster to pull images from the Google Container Registry.
# A GCP Project has 1 GCR Registry per region, which is backed by a GCS Bucket.
# You grant access to the registry by granting access to its underlying storage bucket.
resource "google_service_account" "digital-ocean-cluster" {
  account_id   = "digital-ocean-cluster"
  display_name = "digital-ocean-cluster"
}

# Grant the service account read access to buckets in the entire GCP project.
# Unlike access to an individual storage bucket, this does not require pushing an image first.
# NOTE: possible roles = roles/storage.admin, roles/storage.objectViewer
resource "google_project_iam_member" "digital-ocean-cluster" {
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.digital-ocean-cluster.email}"
}
