// import { AutoScalingClient } from '@aws-sdk/client-auto-scaling';
import { EC2Client, TerminateInstancesCommand } from '@aws-sdk/client-ec2'; // Import from AWS SDK v3

const ec2Client = new EC2Client();
// const asgClient = new AutoScalingClient();

export async function terminateInstance(instanceId: string) {
  // const setProtectionCommand = new SetInstanceProtectionCommand({
  //   InstanceIds: [instanceId],
  //   AutoScalingGroupName: 'your-auto-scaling-group-name',
  //   ProtectedFromScaleIn: false,
  // });

  const command = new TerminateInstancesCommand({ InstanceIds: [instanceId] });
  await ec2Client.send(command);
}