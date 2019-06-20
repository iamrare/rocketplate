require('dotenv-safe').config();

const fs = require('fs');
const path = require('path');

const dotenv = require('dotenv');
const webpack = require('webpack');
const pick = require('lodash/pick');

const envVars = Object.keys(
  dotenv.parse(fs.readFileSync(path.join(__dirname, '.env.example'), 'utf8'))
);

const env =
  process.env.NODE_ENV === 'production'
    ? // Picks environment vars from .env.example out from the environment, so k8s
      // can set whatever env it needs
      pick(process.env, envVars)
    : dotenv.parse(fs.readFileSync(path.join(__dirname, '.env'), 'utf8'));

module.exports = {
  webpack: config => {
    config.plugins.push(
      new webpack.DefinePlugin({
        'process.env': JSON.stringify(env)
      })
    );
    return config;
  }
};
