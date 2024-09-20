bring cloud;
bring aws;

pub class Garbage impl std.IHostedLiftable {
  q: cloud.Queue;

  new() {
    let q = new cloud.Queue();
    this.q = q;

    q.setConsumer(inflight (instanceId) => {
      log("hello, I am terminating instance {instanceId}");
      Garbage.terminateInstance(instanceId);
    });
  }
  
  pub inflight toss(instanceId: str) {
    this.q.push(instanceId);
  }

  extern "./garbage.ts"
  static inflight terminateInstance(instanceId: str): void;

  pub onLift(host: std.IInflightHost, ops: Array<str>) {
    if let fn = aws.Function.from(host) {
      fn.addPolicyStatements(
        {
          effect: aws.Effect.ALLOW,
          actions: ["ec2:TerminateInstances"],
          resources: ["*"],
        },
      );
    }
  }
}
