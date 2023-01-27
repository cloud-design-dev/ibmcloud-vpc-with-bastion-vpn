# ibmcloud-mzr-lab

Terraform code to deploy an IBM Cloud MZR VPC with a VPN or Bastion host. This is a work in progress and currently creates:

 - :white_check_mark:  MZR VPC 
 - :white_check_mark:  Public Gateway per zone for Frontend subnets
 - :white_check_mark:  Frontend subnet per zone 
 - :white_check_mark:  Frontend Security Group for SSH, Web, and VPN
    - Inbound: `80/tcp`, `443/tcp`, `22/tcp`, `51280/udp`
    - Outbound: `all`
 - :white_check_mark:  Cloud Object Storage instance for flowlogs
 - :white_check_mark:  IAM Authorization policy so that Flowlogs can write to the COS instance.
 - :white_check_mark:  COS bucket for each Frontend subnet  
 - :white_check_mark:  Flowlogs collector for each Frontend subnet 
 - :x: Observability instances with ability to use existing ones or deploy new ones
 - :x: VPN server with Wireguard 
 - :x: Bastion Server 

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | 2.2.3 |
| <a name="provider_ibm"></a> [ibm](#provider\_ibm) | 1.50.0-beta0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.4.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cos"></a> [cos](#module\_cos) | git::https://github.com/terraform-ibm-modules/terraform-ibm-cos | v5.3.1 |
| <a name="module_fowlogs_cos_bucket"></a> [fowlogs\_cos\_bucket](#module\_fowlogs\_cos\_bucket) | git::https://github.com/terraform-ibm-modules/terraform-ibm-cos | v5.3.1 |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git | v1.0.5 |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | terraform-ibm-modules/vpc/ibm//modules/security-group | 1.1.1 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-ibm-modules/vpc/ibm//modules/vpc | 1.1.1 |

## Resources

| Name | Type |
|------|------|
| [ibm_iam_authorization_policy.cos_flowlogs](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.50.0-beta0/docs/resources/iam_authorization_policy) | resource |
| [ibm_is_flow_log.frontend](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.50.0-beta0/docs/resources/is_flow_log) | resource |
| [random_shuffle.region](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/shuffle) | resource |
| [random_string.prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [ibm_is_zones.regional](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.50.0-beta0/docs/data-sources/is_zones) | data source |
| [ibm_resource_instance.cos](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.50.0-beta0/docs/data-sources/resource_instance) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_existing_cos_instance"></a> [existing\_cos\_instance](#input\_existing\_cos\_instance) | The name of an existing COS instance to use. If not specified, a new instance will be created. | `string` | `""` | no |
| <a name="input_existing_resource_group"></a> [existing\_resource\_group](#input\_existing\_resource\_group) | Resource group to use for all deployed resources. If not specified, a new one will be created. | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Project owner or identifier. This is used as a tag on all supported resources. | `string` | n/a | yes |
| <a name="input_project_prefix"></a> [project\_prefix](#input\_project\_prefix) | Prefix to be added to all deployed resources. If none provided, one will be automatically generated. | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | Region to deploy resources to. If not specified, one of the following will be used: 'ca-tor' / 'jp-osa' / 'au-syd' /'jp-tok' | `string` | `""` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | Resource group to use for all deployed resources. If not specified the 'CDE' resource group will be used. | `string` | n/a | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cos_bucket_names"></a> [cos\_bucket\_names](#output\_cos\_bucket\_names) | n/a |
| <a name="output_cos_instance_guid"></a> [cos\_instance\_guid](#output\_cos\_instance\_guid) | The details of the COS instance. |
| <a name="output_frontend_subnet_ids"></a> [frontend\_subnet\_ids](#output\_frontend\_subnet\_ids) | The IDs of the frontend subnets. |
| <a name="output_public_gateway_ids"></a> [public\_gateway\_ids](#output\_public\_gateway\_ids) | The IDs of the public gateways. |
| <a name="output_region"></a> [region](#output\_region) | IBM Cloud Region where resources are deployed. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC. |
<!-- END_TF_DOCS -->%  
