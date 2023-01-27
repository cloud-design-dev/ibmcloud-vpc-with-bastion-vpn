provider "ibm" {
  region = local.region
}

provider "logdna" {
  alias      = "at"
  servicekey = module.logging.activity_tracker_resource_key != null ? module.logging.activity_tracker_resource_key : ""
  url        = local.at_endpoint
}

provider "logdna" {
  alias      = "ld"
  servicekey = module.logging.logdna_resource_key != null ? module.logging.logdna_resource_key : ""
  url        = local.at_endpoint
}