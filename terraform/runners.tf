module "runner" {
  source = "./runner"
  for_each = {
    sample = {}
  }
  name   = each.key
  region = var.gcp_region
}
