pub enum Size {
  small,
  medium,
  large,
  xlarge,
}

pub enum Provider {
  aws,
  gcp,
  azure
}

pub struct ClusterOptions {
  size: Size?;
  region: str?;
  provider: Provider?;
}

// TODO: something like TypeScript's Required<T>
pub struct ClusterAttributes {
  size: Size;
  region: str;
  provider: Provider;
}

pub struct Cluster {
  name: str;
  host: Host;
}

pub struct Host extends ClusterAttributes {
  instanceId: str;
  publicIp: str;
  sshPrivateKey: str;
  kubeconfig: str;
  registryPassword: str;
}

pub struct ClusterList {
  clusters: Array<Cluster>;
}

pub class Defaults {
  pub static inflight region(): str {
    return "us-east-1";
  }

  pub static inflight provider(): Provider {
    return Provider.aws;
  }

  pub static inflight size(): Size {
    return Size.medium;
  }
}