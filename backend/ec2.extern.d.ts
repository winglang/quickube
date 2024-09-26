export default interface extern {
  moveElasticIp: (source: Host, target: Host) => Promise<void>,
}
export enum Provider {
  aws = 0,
  gcp = 1,
  azure = 2,
}
export enum Size {
  small = 0,
  medium = 1,
  large = 2,
  xlarge = 3,
}
export interface Host {
  readonly instanceId: string;
  readonly instanceType: string;
  readonly kubeconfig: string;
  readonly provider: Provider;
  readonly publicDns: string;
  readonly publicIp: string;
  readonly region: string;
  readonly size: Size;
}