const yargs = require("yargs");
const kubeconfig = require("./kubeconfig.cjs");
const client = require("./client.cjs");

const commands = {
  async new(opts) {
    const info = await client.newCluster(opts);
    console.log(`Created cluster "${info.name}"`);
    if (!opts["skip-kubeconfig"]) {
      await kubeconfig.addCluster(info.kubeconfig);
    }

    return info;
  },

  async ls() {
    const response = await client.listClusters();
    const current = await kubeconfig.currentContext();

    for (const c of response.clusters) {
      const prefix = c === current ? "* " : "  ";
      console.log(prefix + c);
    }
  },

  async rm(opts) {
    if (!opts.name) {
      throw new Error("The 'rm' take 1 argument (cluster name)");
    }

    const name = opts.name;
    const result = await client.deleteCluster(name);
    if (!result.deleted) {
      console.log(`You don't have a cluster called ${name}, so I guess it's deleted, ha?`);
      return;
    }

    if (!opts["skip-kubeconfig"]) {
      await kubeconfig.deleteCluster(name);
    }

    console.log(`Cluster "${name}" is gone forever`);
  },

  async use(opts) {
    if (!opts.name) {
      throw new Error("The 'use' take 1 argument (cluster name)");
    }

    const name = opts.name;
    const info = await client.getCluster(name);
    await kubeconfig.addCluster(info.kubeconfig);
  }
};

exports.commands = commands;
exports.main = async function main() {
  return yargs
  .help()

  .command("new", "Creates a new cluster", yargs => yargs
    .option("name", {
      alias: "n",
      description: "Cluster name",
      type: "string",
      required: false,
    })
    .option("size", {
      alias: "s",
      description: "Cluster size",
      type: "string",
      required: false,
    })
    .option("region", {
      alias: "r",
      description: "Cluster region",
      type: "string",
      required: false,
    })
    .option("provider", {
      alias: "p",
      description: "Cloud provider",
      type: "string",
      required: false,
    })
    .option("skip-kubeconfig", {
      alias: "k",
      description: "Skip adding the cluster to kubeconfig",
      type: "boolean",
      required: false,
    }), argv => commands.new(argv))

  .command("ls", "Lists clusters", argv => commands.ls(argv))

  .command("rm [name]", "Deletes a cluster", yargs => yargs
    .positional("name", {
      description: "Cluster name",
      type: "string",
      required: true,
    })
    .option("skip-kubeconfig", {
      alias: "k",
      description: "Skip removing the cluster from kubeconfig",
      type: "boolean",
      required: false,
    }), argv => commands.rm(argv))

  .command("use [name]", "Uses a cluster", yargs => yargs
    .positional("name", {
      description: "Cluster name",
      type: "string",
      required: true,
    }), argv => commands.use(argv))

  .showHelpOnFail(true)
  .fail((message, err) => {
    if (message) {
      console.error(message);
    }

    if (err) {
      console.error(err.stack);
    }
    
    process.exit(1);
  })
  .argv;
}

