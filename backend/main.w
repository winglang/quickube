bring cloud;
bring "./names" as names;
bring "./types.w" as t;
bring "./clusters.w" as c;
bring "./api.w" as a;
bring "./pool.w" as p;
bring "./bucket.w" as b;
bring "./dns" as d;
bring "./capacity.w" as cp;
bring util;

let pool = new p.Pool();

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

new cp.Capacity(
  size: t.Size.small,
  count: 5,
  pool: pool.bucket,
) as "SmallCapacity";

new cp.Capacity(
  size: t.Size.medium,
  count: 3,
  pool: pool.bucket,
) as "MediumCapacity";

new cp.Capacity(
  size: t.Size.large,
  count: 2,
  pool: pool.bucket,
) as "LargeCapacity";

new a.Api(
  user: util.env("API_USER"),
  clusters: new c.Clusters(),
  names: new names.NameGenerator(),
  pool: pool,
  dns: dns,
  customDomain: {
    cname: "api",
    zoneName: util.env("DNSIMPLE_DOMAIN"),
    certificateArn: util.env("CERTIFICATE_ARN"),
    dnsimpleAccountId: util.env("DNSIMPLE_ACCOUNT_ID"),
  },
);
