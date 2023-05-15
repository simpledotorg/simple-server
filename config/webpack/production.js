process.env.NODE_ENV = process.env.NODE_ENV || 'production'

const webpackConfig = require('./base')
const TerserPlugin = require("terser-webpack-plugin");

webpackConfig["optimization"] = {
  minimizer: [new TerserPlugin()]
}

module.exports = webpackConfig
