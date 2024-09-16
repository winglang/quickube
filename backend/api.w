bring cloud;
bring "./names.w" as n;
bring "./types.w" as t;
bring "./clusters.w" as c;
bring "./pool.w" as p;

pub struct ApiProps {
  clusters: c.Clusters;
  pool: p.Pool;
  names: n.INameGenerator;
  user: str;
}

pub class Api {
  pub url: str;

  new(props: ApiProps) {
    let user = props.user;
    let api = new cloud.Api(cors: true);
    let pool = props.pool;

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

      if let host = pool.tryAlloc(
        provider: options.provider ?? t.Defaults.provider(),
        region: options.region ?? t.Defaults.region(),
        size: options.size ?? t.Defaults.size()
      ) {

        let name = names.next();
    
        let cluster: t.Cluster = { name, host };
      
        clusters.put(user, cluster);
    
        // TODO: yak!
        return statusOk(unsafeCast(cluster));
      } else {
        return statusError(503, "No available hosts in pool that match the requested attributes: {Json.stringify(options)}");
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
        let deleted = clusters.delete(user, name);
        return statusOk({ name, deleted });
      }
      
      return statusError(400, "Cluster name is required");
    });

    api.get("/clusters/:name/creds", inflight () => {
    
    });
  }
}
