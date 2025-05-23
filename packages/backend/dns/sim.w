bring "./api.w" as api;
bring cloud;

pub class DnsSimulation impl api.IDns {
  records: cloud.Bucket;

  new() {
    this.records = new cloud.Bucket();
  }

  pub inflight tryResolve(hostname: str): str? {
    return this.records.tryGet(hostname);
  }

  pub inflight addARecord(name: str, ip: str): str {
    let hostname = "{name}.dummy.com";
    this.records.put(hostname, ip);
    return hostname;
  }

  pub inflight removeARecord(name: str, ip: str) {
    let hostname = "{name}.dummy.com";
    this.records.delete(hostname);
  }

  pub inflight tryFindARecord(name: str): api.Record? {
    let hostname = "{name}.dummy.com";
    if let ip = this.records.tryGet(hostname) {
      return {
        name: name,
        content: ip,
        type: "A",
        id: 1111
      };
    }

    return nil;
  }
}
