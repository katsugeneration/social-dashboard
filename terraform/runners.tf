module "runner" {
  source = "./runner"
  for_each = {
    jasso-gakuseiseikatsu-stats-importer = {}
    ja-kakei-chousa-importer = {}
  }
  name   = each.key
  region = var.gcp_region
}
