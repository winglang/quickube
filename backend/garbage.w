bring cloud;

pub class Garbage {
  q: cloud.Queue;

  new() {
    let q = new cloud.Queue();
    this.q = q;

    q.setConsumer(inflight (instanceId) => {
      log("terminating instance {instanceId}");
      Garbage.terminateInstance(instanceId);
    });
  }
  
  pub inflight toss(instanceId: str) {
    this.q.push(instanceId);
  }

  extern "./garbage.ts"
  static inflight terminateInstance(instanceId: str): void;
}
