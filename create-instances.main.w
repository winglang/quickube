bring util;
bring "./backend" as backend;

let addCapacity = (size: backend.Size, count: num) => {
  for i in 0..count {
    new backend.cluster.Cluster(size: size) as "{size}-{i}";
  }
};

addCapacity(backend.Size.small, 10);
addCapacity(backend.Size.medium, 2);
addCapacity(backend.Size.large, 1);
