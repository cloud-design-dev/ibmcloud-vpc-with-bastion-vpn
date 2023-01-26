data "ibm_resource_group" "resource_group" {
  name = (var.resource_group != "" ? var.resource_group : "default")
}

data "external" "env" {
  program = ["jq", "-n", "env"]
}

data "ibm_is_zones" "regional" {
  region = local.region
}