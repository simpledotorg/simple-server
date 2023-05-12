process.env.NODE_ENV = process.env.NODE_ENV || 'production'

const webpackConfig = require('./base')
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');

webpackConfig["optimization"] = {}
webpackConfig["optimization"]["minimizer"] = [new UglifyJsPlugin({})]

module.exports = webpackConfig
