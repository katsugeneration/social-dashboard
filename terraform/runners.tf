module "runner" {
  source = "./runner"
  for_each = {
    jasso-gakuseiseikatsu-stats-importer = {}
  }
  name   = each.key
  region = var.gcp_region
}
