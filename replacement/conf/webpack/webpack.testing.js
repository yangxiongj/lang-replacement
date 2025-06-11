const webpackMerge = require('webpack-merge');
const commonConfig = require('/conf/webpack/webpack.common.js');

module.exports = webpackMerge(commonConfig, {
  mode: 'development',
  devtool: 'inline-source-map',
  module: {
    rules: [
      {
        test: /\.(woff|woff2|eot|ttf|svg|ico|png|jpg|gif)$/,
        use: [
          {
            loader: 'file-loader'
          }
        ]
      }
    ]
  }
}); 