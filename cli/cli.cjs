const kubeconfig = require("./kubeconfig.cjs");
const client = require("./client.cjs");

const commands = {
  async new(args) {
    const opts = {};

    while (args.length > 0) {
      const next = args.shift();
      if (next.startsWith("--")) {
        const key = next.substring(2);
        const value = args.shift();
        if (!value) {
          throw new Error(`Missing value for option "--${key}"`);
        }
        if (value?.startsWith("--")) {
          throw new Error(`Invalid value "${value}" for option "${key}"`);
        }

        opts[key] = value;
      }
    }
    
    if (args.length !== 0) {
      throw new Error("The 'new' command does not take any arguments");
    }
  
    const info = await client.newCluster(opts);
    console.log(`Created cluster "${info.name}"`);
    await kubeconfig.addCluster(info.kubeconfig);
  },

  async ls(args) {
    const response = await client.listClusters();
    const current = await kubeconfig.currentContext();

    for (const c of response.clusters) {
      const prefix = c === current ? "* " : "  ";
      console.log(prefix + c);
    }
  },

  async rm(args) {
    if (args.length !== 1) {
      throw new Error("The 'rm' take 1 argument (cluster name)");
    }

    const name = args[0];
    const result = await client.deleteCluster(name);
    if (!result.deleted) {
      console.log(`You don't have a cluster called ${name}, so I guess it's deleted, ha?`);
      return;
    }

    await kubeconfig.deleteCluster(name);
    console.log(`Cluster "${name}" is gone forever`);
  },

  async use(args) {
    if (args.length !== 1) {
      throw new Error("The 'use' take 1 argument (cluster name)");
    }

    const name = args[0];
    const info = await client.getCluster(name);
    await kubeconfig.addCluster(info.kubeconfig);
  }
};

exports.main = async function main(args) {
  const command = args[0];

  if (!command || command === "--help") {
    usage(!command ? 1 : 0);
  }

  const handler = commands[command];

  if (!handler) {
    console.error(`Unknown command "${command}"`);
    console.error();
    usage(1);
  }

  await handler(args.slice(1));
}

function usage(code) {
  console.log("Usage: qkube COMMAND");
  console.log("");
  console.log("Commands:");
  console.log("  new\tCreates a new cluster");
  console.log("  ls\tLists clusters");
  console.log("  rm\tDeletes a cluster");
  console.log("  use\tSwitch to use a cluster");
  console.log("");
  process.exit(code);
}
