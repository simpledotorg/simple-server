process.env.NODE_ENV = process.env.NODE_ENV || 'production'

const webpackConfig = require('./base')
const TerserPlugin = require("terser-webpack-plugin");

console.log("========================")
console.log(webpackConfig)
webpackConfig["optimization"]["minimizer"] = [new TerserPlugin()]
webpackConfig["optimization"]["minimize"] = true
console.log("========================")
console.log(webpackConfig)

module.exports = webpackConfig
