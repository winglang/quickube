bring expect;
bring cloud;
bring fs;
bring "./pool.w" as p;
bring "./types.w" as t;
bring "./bucket.w" as b;
bring "./pool-populate.w" as pp;

let pool = new p.Pool();

test "starts empty" {
  let x = pool.tryAlloc(provider: t.Provider.aws, region: "us-east-1", size: t.Size.medium);
  expect.nil(x);
}

test "object is deleted after alloc" {
  pool.add(
    t.Host {
      provider: t.Provider.aws,
      instanceId: "i-small-001",
      region: "us-east-1",
      size: t.Size.small,
      kubeconfig: "<kubeconfig-0>",
      publicIp: "1.2.3.0",
      instanceType: "t4g.small",
      publicDns: "ec2-1-2-3-0.compute-1.amazonaws.com"
    }
  );

  pool.add(
    t.Host {
      provider: t.Provider.aws,
      instanceId: "i-medium-001",
      region: "us-east-1",
      size: t.Size.medium,
      kubeconfig: "<kubeconfig-1>",
      publicIp: "1.2.3.99",
      instanceType: "t4g.small",
      publicDns: "ec2-1-2-3-99.compute-1.amazonaws.com"
    }
  );

  expect.equal(pool.bucket.list(), ["aws/us-east-1/small/i-small-001", "aws/us-east-1/medium/i-medium-001"]);

  let x = pool.tryAlloc(provider: t.Provider.aws, region: "us-east-1", size: t.Size.small);

  expect.equal(x, {
    instanceId: "i-small-001",
    provider: "aws",
    region: "us-east-1",
    size: "small",
    kubeconfig: "<kubeconfig-0>",
    publicIp: "1.2.3.0",
    instanceType: "t4g.small",
    publicDns: "ec2-1-2-3-0.compute-1.amazonaws.com"
  });

  // the object should be deleted from the bucket
  expect.equal(pool.bucket.list(), [
    "aws/us-east-1/medium/i-medium-001"
  ]);

  // cannot allocate another small instance
  let y = pool.tryAlloc(provider: t.Provider.aws, region: "us-east-1", size: t.Size.small);
  expect.nil(y);
}