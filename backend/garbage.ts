import { EC2Client, TerminateInstancesCommand } from '@aws-sdk/client-ec2';
import extern from "./garbage.extern";

const ec2Client = new EC2Client();

export const terminateInstance: extern["terminateInstance"] = async (instanceId) => {
  try {
    console.log(`Terminating instance: ${instanceId}`);
    const command = new TerminateInstancesCommand({ InstanceIds: [instanceId] });
    const response = await ec2Client.send(command);
    console.log(`Initiated termination of instance ${instanceId}`);
  } catch (error) {
    // TODO: yakk! wing swallows this error so I have no visibility unless I log it here
    console.error(`Error terminating instance ${instanceId}:`, error);
  }
};