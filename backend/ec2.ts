import { EC2Client, AssociateAddressCommand, DisassociateAddressCommand } from "@aws-sdk/client-ec2";
import extern from "./ec2.extern";

const client = new EC2Client();

export const moveElasticIp: extern["moveElasticIp"] = async (source, target) => {
  // release address from source
  await disassociateElasticIp(source.publicIp);

  // associate it with the target
  await associateElasticIp(target.instanceId, source.publicIp);

  // release the old elastic ip from the target
  await disassociateElasticIp(target.publicIp);
}

async function disassociateElasticIp(elasticIp: string) {
  const command = new DisassociateAddressCommand({ PublicIp: elasticIp });
  await client.send(command);
}

async function associateElasticIp(instanceId: string, elasticIp: string) {
  const command = new AssociateAddressCommand({ InstanceId: instanceId, PublicIp: elasticIp });
  await client.send(command);
}
