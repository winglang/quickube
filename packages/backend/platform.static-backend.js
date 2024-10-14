// platform.static-backend.js

exports.Platform = class TFBackend {
  postSynth(config) {
    config.terraform.backend = {
      s3: {
        bucket: process.env.TF_BACKEND_BUCKET,
        region: process.env.TF_BACKEND_REGION,
        key: process.env.TF_BACKEND_KEY,
        dynamodb_table: process.env.TF_BACKEND_DYNAMODB_TABLE
      }
    }
    return config;
  }
}