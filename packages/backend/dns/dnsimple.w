bring "./api.w" as api;
bring cloud;
bring http;

pub struct DnsimpleProps {
  token: str;
  accountId: str;
  domain: str;

}

pub class Dnsimple impl api.IDns {
  props: DnsimpleProps;

  new(props: DnsimpleProps) {
    this.props = props;

  }

  pub inflight addARecord(name: str, ip: str): str {
    let url = "https://api.dnsimple.com/v2/{this.props.accountId}/zones/{this.props.domain}/records";

    let res = http.post(url, {
      headers: {
        "Authorization": "Bearer {this.props.token}",
        "Accept": "application/json",
        "Content-Type": "application/json"
      },
      body: Json.stringify({
        "name": name,
        "type": "A",
        "content": ip,
        "ttl": 3600
      })
    });

    if (res.status != 201) {
      throw "Failed to create A record: {res.status} {res.body}";
    }

    let hostname = "{name}.{this.props.domain}";
    return hostname;
  }

  pub inflight tryFindARecord(name: str): api.Record? {
    let url = "https://api.dnsimple.com/v2/{this.props.accountId}/zones/{this.props.domain}/records";

    // First, we need to find the record ID
    let listRes = http.get("{url}?name={name}&type=A", {
      headers: {
        "Authorization": "Bearer {this.props.token}",
        "Accept": "application/json",
      }
    });

    if (listRes.status != 200) {
      throw "Failed to list records: {listRes.status} {listRes.body}";
    }

    // TODO: yakk!
    let response = GetRecordsResponse.parseJson(listRes.body);
    if response.data.length == 0 {
      return nil;
    }

    return response.data[0];
  }

  pub inflight removeARecord(name: str, ip: str): void {
    if let record = this.tryFindARecord(name) {

      // if the IP is the same, we don't need to do anything
      if record.content != ip {
        return;
      }

      let deleteUrl = "https://api.dnsimple.com/v2/{this.props.accountId}/zones/{this.props.domain}/records/{record.id}";

      http.delete(deleteUrl, {
        headers: {
          "Authorization": "Bearer {this.props.token}",
          "Accept": "application/json"
        }
      });
    }
  }
}

struct GetRecordsResponse {
  data: Array<api.Record>;
}
