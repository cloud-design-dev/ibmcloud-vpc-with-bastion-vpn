output "vpc_id" {
  value = module.vpc.vpc_id[0]
}

output "region" {
  value = local.region
}

output "subnet_ids" {
  value = module.vpc.subnet_ids
}

output "public_gateway_ids" {
  value = module.vpc.public_gateway_ids
}