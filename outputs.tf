output "vpc_id" {
  description = "The ID of the VPC."
  value       = module.vpc.vpc_id[0]
}

output "region" {
  description = "IBM Cloud Region where resources are deployed."
  value       = local.region
}

output "frontend_subnet_ids" {
  description = "The IDs of the frontend subnets."
  value       = module.vpc.subnet_ids
}

output "public_gateway_ids" {
  description = "The IDs of the public gateways."
  value       = module.vpc.public_gateway_ids
}

output "cos_instance_guid" {
  description = "The details of the COS instance."
  value       = local.cos_guid
}

output "cos_bucket_names" {
  value = flatten(module.fowlogs_cos_bucket.*.bucket_name)
}

output "bastion_public_ip" {
  description = "Public IP of the bastion instance."
  value       = ibm_is_floating_ip.bastion.address
}