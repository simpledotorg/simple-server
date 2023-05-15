process.env.NODE_ENV = process.env.NODE_ENV || 'production'

const webpackConfig = require('./base')

webpackConfig["optimization"] = {
  minimize: true,
}

module.exports = webpackConfig
