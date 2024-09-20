import { EC2Client, TerminateInstancesCommand } from '@aws-sdk/client-ec2';

const ec2Client = new EC2Client();

export async function terminateInstance(instanceId: string) {
  const command = new TerminateInstancesCommand({ InstanceIds: [instanceId] });
  await ec2Client.send(command);
  console.log(`Initiated termination of instance ${instanceId}`);
}