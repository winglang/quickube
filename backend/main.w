bring cloud;
bring "./names" as names;
bring "./types.w" as t;
bring "./clusters.w" as c;
bring "./api.w" as a;
bring "./pool.w" as p;
bring "./bucket.w" as b;
bring "./dns" as d;
bring aws;
bring util;

// TODO: yakk!

let pool = () => {
  if util.env("WING_TARGET") == "sim" {
    return new b.SimulatedPoolBucket();
  } else {
    return new b.AwsBucketRef(util.env("Q8S_POOL_BUCKET"));
  }
}();

let dns = () => {
  if util.env("WING_TARGET") == "sim" {
    return new d.DnsSimulation();
  } else {
    return new d.Dnsimple(
      token: util.env("DNSIMPLE_TOKEN"),
      accountId: util.env("DNSIMPLE_ACCOUNT_ID"),
      domain: util.env("DNSIMPLE_DOMAIN"),
    );
  }
}();

new a.Api(
  user: util.env("API_USER"),
  clusters: new c.Clusters(),
  names: new names.NameGenerator(),
  pool: new p.Pool(bucket: pool),
  dns: dns,
  customDomain: {
    cname: "api",
    zoneName: util.env("DNSIMPLE_DOMAIN"),
    certificateArn: util.env("CERTIFICATE_ARN"),
    dnsimpleAccountId: util.env("DNSIMPLE_ACCOUNT_ID"),
  },
);
