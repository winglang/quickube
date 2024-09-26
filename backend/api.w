bring cloud;
bring util;
bring fs;
bring "./names" as names;
bring "./types.w" as t;
bring "./clusters.w" as c;
bring "./pool.w" as p;
bring "./dns" as d;
bring "./kubeconfig.w" as kc;
bring "./custom-domain.w" as cd;
bring "./garbage.w" as g;

pub struct ApiProps {
  clusters: c.Clusters;
  pool: p.Pool;
  names: names.INameGenerator;
  user: str;
  dns: d.IDns;
  customDomain: cd.CustomDomainConfig?;
  garbage: g.Garbage;
}

pub class Api {
  pub url: str;
  dns: d.IDns;

  new(props: ApiProps) {
    let user = props.user;
    let api = new cloud.Api(cors: true);

    if let customDomain = props.customDomain {
      new cd.CustomDomain(
        api: api,
        cname: customDomain.cname,
        zoneName: customDomain.zoneName,
        certificateArn: customDomain.certificateArn,
        dnsimpleAccountId: customDomain.dnsimpleAccountId,
      );
    }

    let pool = props.pool;
    this.dns = props.dns;

    this.url = api.url;

    let names = props.names;
    let clusters = props.clusters;
    
    let statusError = inflight (status: num, message: str) => {
      return {
        status,
        body: Json.stringify({ error: message, status }),
        headers: {
          "content-type": "application/json"
        }
      };
    };
    
    let statusOk = inflight (obj: Json) => {
      return {
        body: Json.stringify(obj, indent: 2),
        headers: {
          "content-type": "application/json"
        }
      };
    };
    
    api.post("/clusters", inflight (req) => {
    
      // TODO: yakk!!
      let var body = req.body!;
      if req.body == "" || req.body == nil {
        body = Json.stringify({});
      }
    
      let options = t.ClusterOptions.parseJson(body);

      let attributes = t.ClusterAttributes {
        provider: options.provider ?? t.Defaults.provider(),
        region: options.region ?? t.Defaults.region(),
        size: options.size ?? t.Defaults.size()
      };

      let subdomain = options.name ?? names.next();

      // check if this subdomain is available
      if this.dns.tryFindARecord(subdomain) != nil {
        return statusError(409, "Cluster name '{subdomain}' not available");
      }

      if let host = pool.tryAlloc(attributes) {
        log("Adding host mapping: {subdomain} => {host.publicIp}");
        let hostname = this.dns.addARecord(subdomain, host.publicIp);

        // mangle the kubeconfig to match our new hostname
        let kubeconfig = kc.renderKubeConfig(host.kubeconfig, hostname: hostname);

        let cluster: t.Cluster = {
          name: hostname,
          hostname, 
          kubeconfig, 
          host: host,
          provider: host.provider,
          region: host.region,
          size: host.size,
        };
      
        clusters.put(user, cluster);
    
        // TODO: yak!
        return statusOk(unsafeCast(cluster));
      } else {
        return statusError(503, "No available clusters that match the request: {Json.stringify(attributes)}");
      }
    });

    api.post("/cluster/:name/recycle", inflight (req) => {
      // TODO: yakk!!
      let var body = req.body!;
      if req.body == "" || req.body == nil {
        body = Json.stringify({});
      }
    
      let options = t.ClusterOptions.parseJson(body);

      if let name = req.vars.tryGet("name") {
        if let c = clusters.tryGet(user, name) {
          let oldHost = c.host;

          let attributes = t.ClusterAttributes {
            provider: options.provider ?? c.provider,
            region: options.region ?? c.region,
            size: options.size ?? c.size
          };
    
          if let newHost = pool.tryAlloc(attributes) {


            // TODO: this is not working because our instances do not have an elastic ip associated with them for now
            // we need to add a lifecycle hook to the autoscaling group to associate an elastic ip with the instance
            // when it is created and only then we will be able to preserve the ip across instance recycling
            // >> ec2.switchElasticIp(oldHost, newHost);



          } else {
            return statusError(409, "No capacity available to recycle {name}");
          }
           

          props.garbage.toss(c.host.instanceId);
          return statusOk({ name, recycled: true });
        } else {
          return statusError(404, "Cluster '{name}' not found");
        }
      } else {
        return statusError(400, "Cluster name is required");
      }
    });
    
    api.get("/clusters", inflight () => {
      // TODO: yak!
      return statusOk(unsafeCast(t.ClusterList {
        clusters: clusters.list(user),
      }));
    });
    
    api.get("/clusters/:name", inflight (req) => {
      if let name = req.vars.tryGet("name") {
        if let c = clusters.tryGet(user, name) {
          return statusOk(unsafeCast(c));
        } else {
          return statusError(404, "Cluster '{name}' not found");
        }
      }
      
      return statusError(400, "Cluster name is required");
    });
        
    api.delete("/clusters/:name", inflight (req) => {
      if let name = req.vars.tryGet("name") {
        log("Deleting cluster: {name}");

        if let existing = clusters.tryGet(user, name) {
          let subdomain = existing.hostname.split(".")[0]; // remove the domain
          this.dns.removeARecord(subdomain, existing.host.publicIp);
          let deleted = clusters.delete(user, name);
          props.garbage.toss(existing.host.instanceId);
          return statusOk({ name, deleted });
        } else {
          return statusOk({ name, deleted: false });
        }
      }
      
      return statusError(400, "Cluster name is required");
    });

    api.get("/clusters/:name/creds", inflight () => {
    
    });
  }
}
