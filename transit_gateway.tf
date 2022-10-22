// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_ec2_transit_gateway" "tgw" {
  tags = {
    Name = "transit-gateway"
  }
}

resource "aws_ec2_transit_gateway_route_table" "pre_inspection_route_table" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "pre-inspection-route-table"
  }
}
resource "aws_ec2_transit_gateway_route_table" "post_inspection_route_table" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "post-inspection-route-table"
  }
}

resource "aws_ec2_transit_gateway_route_table" "ingressegress_route_table" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name = "ingressegress-route-table"
  }
}
resource "aws_ec2_transit_gateway_vpc_attachment" "ingressegress_vpc_tgw_attachment" {
  subnet_ids                                      = aws_subnet.ingressegress_vpc_tgw_subnet[*].id
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  vpc_id                                          = aws_vpc.ingressegress_vpc.id
  transit_gateway_default_route_table_association = false
  tags = {
    Name = "ingressegress-vpc-attachment"
  }
}
resource "aws_ec2_transit_gateway_vpc_attachment" "inspection_vpc_tgw_attachment" {
  subnet_ids                                      = aws_subnet.inspection_vpc_tgw_subnet[*].id
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  vpc_id                                          = aws_vpc.inspection_vpc.id
  transit_gateway_default_route_table_association = false
  appliance_mode_support                          = "enable"
  tags = {
    Name = "inspection-vpc-attachment"
  }
}
resource "aws_ec2_transit_gateway_vpc_attachment" "integration_vpc_tgw_attachment" {
  subnet_ids                                      = aws_subnet.integration_vpc_tgw_subnet[*].id
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  vpc_id                                          = aws_vpc.integration_vpc.id
  transit_gateway_default_route_table_association = false
  tags = {
    Name = "integration-vpc-attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "app1_vpc_tgw_attachment" {
  subnet_ids                                      = aws_subnet.app1_vpc_tgw_subnet[*].id
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  vpc_id                                          = aws_vpc.app1_vpc.id
  transit_gateway_default_route_table_association = false
  tags = {
    Name = "app1-vpc-attachment"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "ingressegress_vpc_tgw_attachment_rt_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.ingressegress_vpc_tgw_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ingressegress_route_table.id
}
resource "aws_ec2_transit_gateway_route_table_association" "inspection_vpc_tgw_attachment_rt_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection_vpc_tgw_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.post_inspection_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_association" "integration_vpc_tgw_attachment_rt_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.integration_vpc_tgw_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.pre_inspection_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_association" "app1_vpc_tgw_attachment_rt_association" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app1_vpc_tgw_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.pre_inspection_route_table.id
}

# Routes for ingress/egress route table
# Route incoming traffic to the Inspection VPC attachment
resource "aws_ec2_transit_gateway_route" "ingressegress_route_table_default_route" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.ingressegress_route_table.id
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.inspection_vpc_tgw_attachment.id
  destination_cidr_block = "0.0.0.0/0"
}

# Routes for TGW post_inspection_route_table
resource "aws_ec2_transit_gateway_route" "post_inspection_route_table_internet_route" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.post_inspection_route_table.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.ingressegress_vpc_tgw_attachment.id
  destination_cidr_block         = "0.0.0.0/0"
}

# Route propagations for inspection route table
resource "aws_ec2_transit_gateway_route_table_propagation" "post_inspection_route_table_propagate_app1_vpc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app1_vpc_tgw_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.post_inspection_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "post_inspection_route_table_propagate_integration_vpc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.integration_vpc_tgw_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.post_inspection_route_table.id
}
resource "aws_ec2_transit_gateway_route_table_propagation" "post_inspection_route_table_propagate_ingressegress_vpc" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.post_inspection_route_table.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.ingressegress_vpc_tgw_attachment.id
}

# Routes for pre_inspection_route_table
# Route all outbound traffic to inspection VPC by default
resource "aws_ec2_transit_gateway_route" "pre_inspection_route_table_default_route" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection_vpc_tgw_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.pre_inspection_route_table.id
  destination_cidr_block         = "0.0.0.0/0"
}

resource "aws_ec2_transit_gateway_route_table_propagation" "pre_inspection_route_table_propagate_app1_vpc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app1_vpc_tgw_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.pre_inspection_route_table.id
}
