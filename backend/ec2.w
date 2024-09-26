bring "./types.w" as t;

internal class Util {
  extern "./ec2.ts" static inflight moveElasticIp(source: t.Host, target: t.Host): void;
}