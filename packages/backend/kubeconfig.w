bring fs;
bring util;

struct ClusterProps {
  hostname: str;
}

internal class Util {
  pub static inflight renderKubeConfig(base64: str, props: ClusterProps): Json {
    let hostname = props.hostname;
    let tmpdir = fs.mkdtemp();
    let tmpfile = fs.join(tmpdir, "kubeconfig.yaml");
    fs.writeFile(tmpfile, util.base64Decode(base64));
    let kubeconfig = MutJson fs.readYaml(tmpfile)[0];
    fs.remove(tmpdir);

    let clusterCfg = kubeconfig.get("clusters").getAt(0);
    clusterCfg.get("cluster").set("server", "https://{hostname}:7443");
    clusterCfg.get("cluster").delete("certificate-authority-data");
    clusterCfg.get("cluster").set("insecure-skip-tls-verify", true);
    clusterCfg.set("name", hostname);

    kubeconfig.set("contexts", [
      {
        "name": hostname,
        "context": {
          "cluster": hostname,
          "user": hostname
        },
      }
    ]);

    kubeconfig.set("current-context", hostname);

    let userCfg = kubeconfig.get("users").getAt(0);
    userCfg.set("name", hostname);
    
    return Json.deepCopy(kubeconfig);
  }
}