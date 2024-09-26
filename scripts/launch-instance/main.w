bring "./backend" as b;
bring cloud;

let pool = new cloud.Bucket();

new b.Capacity(
  size: b.Size.small,
  count: 2,
  pool: pool,
);