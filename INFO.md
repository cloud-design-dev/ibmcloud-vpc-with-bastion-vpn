<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | 1.50.0-beta0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_external"></a> [external](#provider\_external) | 2.2.3 |
| <a name="provider_ibm"></a> [ibm](#provider\_ibm) | 1.50.0-beta0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.4.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | terraform-ibm-modules/vpc/ibm//modules/security-group | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-ibm-modules/vpc/ibm//modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [random_shuffle.region](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/shuffle) | resource |
| [random_string.prefix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [external_external.env](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [ibm_is_zones.regional](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.50.0-beta0/docs/data-sources/is_zones) | data source |
| [ibm_resource_group.resource_group](https://registry.terraform.io/providers/IBM-Cloud/ibm/1.50.0-beta0/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_frontend_rules"></a> [frontend\_rules](#input\_frontend\_rules) | A list of security group rules to be added to the Frontend security group | <pre>list(<br>    object({<br>      name      = string<br>      direction = string<br>      remote    = string<br>      tcp = optional(<br>        object({<br>          port_max = optional(number)<br>          port_min = optional(number)<br>        })<br>      )<br>      udp = optional(<br>        object({<br>          port_max = optional(number)<br>          port_min = optional(number)<br>        })<br>      )<br>      icmp = optional(<br>        object({<br>          type = optional(number)<br>          code = optional(number)<br>        })<br>      )<br>    })<br>  )</pre> | <pre>[<br>  {<br>    "direction": "inbound",<br>    "ip_version": "ipv4",<br>    "name": "inbound-vpn-udp",<br>    "remote": "0.0.0.0/0",<br>    "udp": {<br>      "port_max": 51280,<br>      "port_min": 51280<br>    }<br>  },<br>  {<br>    "direction": "inbound",<br>    "ip_version": "ipv4",<br>    "name": "inbound-http",<br>    "remote": "0.0.0.0/0",<br>    "tcp": {<br>      "port_max": 80,<br>      "port_min": 80<br>    }<br>  },<br>  {<br>    "direction": "inbound",<br>    "ip_version": "ipv4",<br>    "name": "inbound-https",<br>    "remote": "0.0.0.0/0",<br>    "tcp": {<br>      "port_max": 443,<br>      "port_min": 443<br>    }<br>  },<br>  {<br>    "direction": "inbound",<br>    "ip_version": "ipv4",<br>    "name": "inbound-ssh",<br>    "remote": "0.0.0.0/0",<br>    "tcp": {<br>      "port_max": 22,<br>      "port_min": 22<br>    }<br>  },<br>  {<br>    "direction": "inbound",<br>    "icmp": {<br>      "code": 0,<br>      "type": 8<br>    },<br>    "ip_version": "ipv4",<br>    "name": "inbound-icmp",<br>    "remote": "0.0.0.0/0"<br>  },<br>  {<br>    "direction": "outbound",<br>    "ip_version": "ipv4",<br>    "name": "all-outbound",<br>    "remote": "0.0.0.0/0"<br>  }<br>]</pre> | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Project owner or identifier. This is used as a tag on all supported resources. | `string` | n/a | yes |
| <a name="input_project_prefix"></a> [project\_prefix](#input\_project\_prefix) | Prefix to be added to all deployed resources. If none provided, one will be automatically generated. | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | Region to deploy resources to. If not specified, one of the following will be used: 'ca-tor' / 'jp-osa' / 'au-syd' /'jp-tok' | `string` | `""` | no |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | Resource group to use for all deployed resources. If not specified the 'CDE' resource group will be used. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_public_gateway_ids"></a> [public\_gateway\_ids](#output\_public\_gateway\_ids) | n/a |
| <a name="output_region"></a> [region](#output\_region) | n/a |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
<!-- END_TF_DOCS -->