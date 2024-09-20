bring "cdktf" as cdktf;
bring "@cdktf/provider-aws" as aws;

pub class Vpc {
  pub vpcId: str;
  pub subnetId: str;

  new() {
    let availabilityZones = new aws.dataAwsAvailabilityZones.DataAwsAvailabilityZones();
    let azNames = availabilityZones.names;

    let vpc = new aws.vpc.Vpc(
      cidrBlock: "10.0.0.0/16",
      enableDnsSupport: true,
      enableDnsHostnames: true,
    );

    let internetGateway = new aws.internetGateway.InternetGateway(
      vpcId: vpc.id,
    );

    let publicRouteTable = new aws.routeTable.RouteTable(
      vpcId: vpc.id,
    );

    let defaultRoute = new aws.route.Route(
      routeTableId: publicRouteTable.id,
      destinationCidrBlock: "0.0.0.0/0",
      gatewayId: internetGateway.id,
    );

    let subnet = new aws.subnet.Subnet(
      vpcId: vpc.id,
      cidrBlock: "10.0.0.0/20",
      availabilityZone: cdktf.Fn.element(azNames, 0),
      mapPublicIpOnLaunch: true,
    );

    let subnetAssociation = new aws.routeTableAssociation.RouteTableAssociation(
      subnetId: subnet.id,
      routeTableId: publicRouteTable.id,
    );

    this.vpcId = vpc.id;
    this.subnetId = subnet.id;
  }
}