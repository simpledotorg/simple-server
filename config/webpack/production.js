process.env.NODE_ENV = process.env.NODE_ENV || 'production'

const webpackConfig = require('./base')
const TerserPlugin = require("terser-webpack-plugin");

webpackConfig["optimization"] = {
  minimize: true,
  minimizer: [new TerserPlugin()],
}

module.exports = webpackConfig
