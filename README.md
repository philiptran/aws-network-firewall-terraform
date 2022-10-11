# AWS Network Firewall - Terraform Sample

This repository contains terraform code to deploy a sample architecture to try AWS Network Firewall. The resources deployed and the architectural pattern they follow is purely for demonstration/testing purposes. If you are looking for a set of approved architectures, read this [blog post](https://aws.amazon.com/blogs/networking-and-content-delivery/deployment-models-for-aws-network-firewall/).

[TODO] The image below is a graphical representation of what resources are defined in the Terraform code in this repository: 
![Architectural Diagram with Two Spoke VPCs, Transit Gateway, Ingress/Egress VPC and Inspection VPC](images/anfw-terraform-TODO.jpg "Architectural Diagram")

The templates deploy three VPCs (`app1-vpc`, `integration-vpc`, `ingress/egress vpc` and `inspection vpc`).
AWS Network Firewall endpoints are deployed in the Inspection VPC. 
Internet egress is configured in the ingress/egress VPC, by deploying NAT Gateways in Public Subnets.

The template deploys two EC2 instances in `app1-vpc` and `integration-vpc` for testing purposes. 
It also deploys resources so that connecting to these instances is enabled via [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html).

### AWS Network Firewall Configuration

The [firewall.tf](firewall.tf) template file contains the definitions of the FW rule-groups that these templates come with by default. 

The [default action](https://docs.aws.amazon.com/network-firewall/latest/developerguide/stateless-default-actions.html) taken by the stateless engine is `Forward to stateful rule groups`.

[Alert logs](https://docs.aws.amazon.com/network-firewall/latest/developerguide/logging-cw-logs.html) are persisted in a dedicated Cloudwatch Log Group (`/aws/network-firewall/alert`).

[Flow logs](https://docs.aws.amazon.com/network-firewall/latest/developerguide/logging-cw-logs.html) are persisted in a dedicated S3 Bucket (`network-firewall-flow-bucket-*`).

The rule-groups configured in the policy are the following:
- `drop-icmp`: this is a stateless rule group that drops all ICMP traffic
- `drop-non-http-between-vpcs`: this stateful rules drops anything but HTTP traffic between spoke VPCs.
- `block-domains`: this stateful rule prevents any HTTP traffic to occur to two FQDNs specified in the rule itself.

The template deploys two instances in `app1-vpc` and `integration-vpc` in the `protected` subnets that you can use to test east-west connectivity (and north-south).

By default, the templates deploy in the `ap-southeast-1` AWS Region.
If you wish to deploy in any other AWS Region, edit the corresponding setting in the [provider.tf](provider.tf) file.

### How-to
1. Install Terraform (0.14.6 or higher)
2. Clone this repository
3. Initialise Terraform `terraform init`
4. Deploy the template with `terraform apply`. 

### Tests
- try a ping between instances in `app1-vpc` and `integration-vpc`: this shouldn't work
- try to SSH to the EC2 Instance in `integration-vpc` from the EC2 Instance in `app1-vpc` (or vice-versa): this shouldn't work
- try to curl the private IP of the EC2 Instance in `integration-vpc` from the EC2 Instance in `app1-vpc` (or vice-versa): this should work
- try a ping to a public IP address: this shouldn't work
- try to `dig` using a public DNS resolver: this shouldn't work
- try to curl https://facebook.com or https://twitter.com: this shouldn't work
- try to curl any other public URL: this should work

### Cleanup
Remember to clean up after your work is complete. You can do that by doing `terraform destroy`.

Note that this command will delete all the resources previously created by Terraform.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the [LICENSE](LICENSE) file.

# ADD-ON

1. Deploy a Private API into the `integration-vpc` to serve as the integration endpoint for App servers running in `app1-vpc`
1. Test the network traffic flow...

## Testing

Check the terraform output and note down the it_test_api_endpoint

Connect to EC2 in `app1-vpc` to make a call to the private API hosted in the `integration-vpc`

```
curl -v GET https://z0xhl2gf87.execute-api.ap-southeast-1.amazonaws.com/default/verify_token
```

Notes:
1. The above endpoint can be access from `integration-vpc` as the API endpoint is created in this VPC and the DNS hostname works.
1. Calling the same endpoint from `app1-vpc` will not resolve the DNS name for the private API endpoint residing in `integration-vpc`.
1. You need to use Route53 alias or the public DNS name of the VPC endpoint with the `Host` header to invoke the private API endpoint from other VPCs.

Examples:

1. Option 1: Use Route53 Alias

```
curl -i https://z0xhl2gf87-vpce-03d66af5360d46719.execute-api.ap-southeast-1.amazonaws.com/default/verify_token?url=https://www.amazon.com
```

1. Option 2: Use the public DNS name of the VPC endpoint with `Host` header

```
curl -i https://vpce-03d66af5360d46719-s7gfnlhd.execute-api.ap-southeast-1.vpce.amazonaws.com/default/verify_token -H "Host: z0xhl2gf87.execute-api.ap-southeast-1.amazonaws.com"
```

Some references:
* https://faun.pub/creating-aws-api-gateway-with-private-endpoint-using-terraform-e5b1f8034982
* [Accessing your private API using a Route53 alias](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-private-api-test-invoke-url.html#apigateway-private-api-route53-alias)

Troubleshooting:
1. API Gateway does not use the latest Lambda version?
