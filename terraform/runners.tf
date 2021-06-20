module "runner" {
  source = "./runner"
  for_each = {
    jasso-gakuseiseikatsu-stats-importer = {}
    e-stat-kakei-chousa-importer = {}
  }
  name   = each.key
  region = var.gcp_region
}
