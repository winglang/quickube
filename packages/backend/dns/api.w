pub interface IDns {
  inflight tryFindARecord(name: str): Record?;
  inflight addARecord(name: str, ip: str): str;
  inflight removeARecord(name: str, ip: str): void;
}

pub struct Record {
  id: num;
  name: str;
  type: str;
  content: str;
}