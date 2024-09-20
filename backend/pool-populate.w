bring fs;
bring "./pool.w" as p;
bring "./types.w" as t;

pub class Util {
  pub static populate(pool: p.Pool) {
    let fixture = fs.readJson("{@dirname}/fixtures/host.json");
    let kubeconfigBase64 = fixture.get("kubeconfig").asStr();
  
    let var i = 0;
  
    let addHost = (provider: t.Provider, region: str, size: t.Size) => {
      let instanceId = "i-{i}";
      let key = "{provider}/{region}/{size}/{instanceId}";
      pool.bucket.addObject(key, Json.stringify(t.Host {
        provider: provider,
        region: region,
        instanceType: "t4g.small",
        size: size,
        publicDns: "ec2-1-2-3-{i}.compute-1.amazonaws.com",
        instanceId: instanceId,
        kubeconfig: kubeconfigBase64,
        publicIp: "1.2.3.{i}",
      }));
  
      i += 1;
    };
  
    // 1 small, 2 medium, 1 large, 0 xlarge
    addHost(t.Provider.aws, "us-east-1", t.Size.small);   // 0
    addHost(t.Provider.gcp, "america", t.Size.small);     // 1
    addHost(t.Provider.aws, "us-east-1", t.Size.medium);  // 2  
    addHost(t.Provider.aws, "us-east-1", t.Size.medium);  // 3
    addHost(t.Provider.aws, "us-east-1", t.Size.large);   // 4
  }
}