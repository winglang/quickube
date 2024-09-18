const yaml = require("yaml");
const fs = require("fs/promises");
const path = require("path");

async function updateKubeConfig(clusterInfo) {
  const kubeconfigFile = path.join(process.env.HOME, ".kube", "config");
  const active = clusterInfo.contexts[0].name;

  try {
    // if kubeconfig exists, we need to update it
    await fs.access(kubeconfigFile, fs.constants.F_OK);

    // read it
    const config = yaml.parseDocument(await fs.readFile(kubeconfigFile, "utf-8")).toJSON();

    const newCluster = clusterInfo.clusters[0];
    config.clusters = (config.clusters ?? []).filter(c => c.name !== newCluster.name);
    config.clusters.push(newCluster);

    const newUser = clusterInfo.users[0];
    config.users = (config.users ?? []).filter(u => u.name !== newUser.name);
    config.users.push(newUser);

    const newContext = clusterInfo.contexts[0];
    config.contexts = (config.contexts ?? []).filter(c => c.name !== newContext.name);
    config.contexts.push(newContext);
    config["current-context"] = newContext.name;
    await fs.writeFile(kubeconfigFile, yaml.stringify(config));
  } catch (e) {
    if (e.code === "ENOENT") {
      // if kubeconfig is not found, just create it with our cluster info. it should have everything!
      await fs.writeFile(kubeconfigFile, yaml.stringify(clusterInfo));
    } else {
      throw e;
    }
  }

  console.log(`Set kubectl context to "${active}"`);
}

exports.updateKubeConfig = updateKubeConfig;