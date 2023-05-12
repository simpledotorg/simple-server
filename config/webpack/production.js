process.env.NODE_ENV = process.env.NODE_ENV || 'production'

const webpackConfig = require('./base')
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');

webpackConfig["plugins"]["UglifyJs"] = new UglifyJsPlugin({
  uglifyOptions: {
    compress: {
      unused: true,
      dead_code: true,
      warnings: false,
    },
    output: {
      comments: false,
    },
  },
})

module.exports = webpackConfig
