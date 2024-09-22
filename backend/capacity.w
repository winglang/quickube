bring "cdktf" as cdktf;
bring "@cdktf/provider-aws" as aws;
bring "@cdktf/provider-null" as tfnull;
bring "@cdktf/provider-local" as local;
bring "./types.w" as t;
bring "./vpc.w" as v;
bring fs;
bring tf;
bring util;
bring cloud;
bring aws as awsw;

pub struct CapacityProps {
  size: t.Size;
  count: num?;
  pool: cloud.Bucket;
}

pub class Capacity {
  new(props: CapacityProps) {
    if util.env("WING_TARGET") != "tf-aws" {
      return this;
    }

    let vpc = new v.Vpc();
    let subnetId = vpc.subnetId;
    let vpcId = vpc.vpcId;

    let poolBucketName = awsw.Bucket.from(props.pool)?.bucketName!;

    let id = nodeof(this).id;
    let workdir = fs.mkdtemp();
    let configPath = "{workdir}/kubeconfig";
    let keyPath = "{workdir}/key.pem";

    let instanceType = this.findInstanceType(props.size);

    let securityGroup = new aws.securityGroup.SecurityGroup(
      description: "quickube security group",
      vpcId: vpcId,

      // allow all egress
      egress: [{
        fromPort: 0,
        toPort: 0,
        protocol: "-1",
        cidrBlocks: ["0.0.0.0/0"],
      }],

      // allow all ingress
      ingress: [{
        fromPort: 0,
        toPort: 65535,
        protocol: "tcp",
        cidrBlocks: ["0.0.0.0/0"],
      }],
    );

    let region = new aws.dataAwsRegion.DataAwsRegion();

    let size: str = unsafeCast(instanceType.size);

    let userData = cdktf.Fn.templatefile("{@dirname}/userdata.sh", {
      tf_qkube_pool_bucket: poolBucketName,
      tf_qkube_size: size,
    });

    let user = "ec2-user";

    // generate an ssh key for our host
    let sshKey = new TlsPrivateKey();

    let keypair = new aws.keyPair.KeyPair(
      publicKey: sshKey.publicKeyOpenSsh,
    );

    let ami = new aws.dataAwsAmi.DataAwsAmi(
      mostRecent: true,
      owners: ["137112412989"],
      filter: [{
        name: "name",
        values: ["amzn2-ami-hvm-*-arm64-gp2"],
      }],
    );

    let role = new aws.iamRole.IamRole(
      assumeRolePolicy: Json.stringify({
        Version: "2012-10-17",
        Statement: [{
          Effect: "Allow",
          Action: "sts:AssumeRole",
          Principal: {
            Service: "ec2.amazonaws.com",
          },
        }],
      }),
    );

    new aws.iamRolePolicy.IamRolePolicy(
      role: role.name,
      policy: Json.stringify({
        Version: "2012-10-17",
        Statement: [{
          Effect: "Allow",
          Action: ["s3:PutObject"],
          Resource: ["arn:aws:s3:::{poolBucketName}/*"],
        }],
      }),
    );

    let instanceProfile = new aws.iamInstanceProfile.IamInstanceProfile(
      role: role.name,
    );

    let launchTemplate = new aws.launchTemplate.LaunchTemplate(
      namePrefix: "quickube-{props.size}-",
      imageId: ami.id,
      instanceType: instanceType.name,
      keyName: keypair.keyName,
      vpcSecurityGroupIds: [securityGroup.id],
      userData: cdktf.Fn.base64encode(userData),
      ebsOptimized: "true",
      iamInstanceProfile: {
        arn: instanceProfile.arn,
      },
      blockDeviceMappings: [{
        deviceName: "/dev/xvda",
        ebs: {
          volumeSize: 8,
          volumeType: "gp2",
          deleteOnTermination: true,
        },
      }],
      metadataOptions: {
        httpEndpoint: "enabled",
        httpTokens: "optional",
        httpPutResponseHopLimit: 2,
        httpProtocolIpv6: "disabled",
      },
      tagSpecifications: [{
        resourceType: "instance",
        tags: {
          Name: "qkube/{props.size}",
        },
      }],
    );

    let asg = new aws.autoscalingGroup.AutoscalingGroup(
      name: "quickube-{props.size}",
      vpcZoneIdentifier: [subnetId],
      desiredCapacity: props.count ?? 1,
      minSize: props.count ?? 1,
      maxSize: props.count ?? 1,
      protectFromScaleIn: true,
      launchTemplate: {
        name: launchTemplate.name,
        version: cdktf.Fn.tostring(launchTemplate.latestVersion)
      },
    );

    new cdktf.TerraformOutput(value: sshKey.privateKeyPem, staticId: true, sensitive: true) as "pem";
  }

  findInstanceType(size: t.Size): t.InstanceType {
    let types = t.Defaults.instanceTypes();
    
    // lookup the instance type based on the size
    for type in types {
      if (type.size == size) {
        return type;
      }
    }
  
    throw "Invalid size: {size}";
  }
}


class TlsPrivateKey {
  pub publicKeyOpenSsh: str;
  pub privateKeyPem: str;

  new() {
    let r = new tf.Resource(
      terraformResourceType: "tls_private_key",
      attributes: {
        algorithm: "RSA",
        rsa_bits: 4096,
      }
    );

    this.publicKeyOpenSsh = r.getStringAttribute("public_key_openssh");
    this.privateKeyPem = r.getStringAttribute("private_key_pem");
  }
}