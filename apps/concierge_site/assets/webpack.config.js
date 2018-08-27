const CopyWebpackPlugin = require('copy-webpack-plugin');
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const OptimizeCSSAssetsPlugin = require("optimize-css-assets-webpack-plugin");
const path = require('path');
const webpack = require('webpack');
const UglifyJsPlugin = require("uglifyjs-webpack-plugin");


module.exports = function(env) {
  return {
    mode: env.production ? 'production' : 'development',
    entry: ["babel-polyfill", "./js/app.js"],
    output: env.production
      ? {
        path: path.resolve(__dirname, '../priv/static/js'),
        filename: 'app.js',
        publicPath: '/',
      }
      : {
        path: path.resolve(__dirname, 'public'),
        filename: 'app.js',
        publicPath: 'http://localhost:8090/',
      },
    devtool: env.production ? 'source-map' : 'eval',
    devServer: {
      headers: {
        'Access-Control-Allow-Origin': '*',
      },
      port: 8090
    },
    module: {
      rules: [
        {
          test: /\.js$/,
          exclude: /node_modules/,
          use: {
            loader: 'babel-loader',
            options: {
              presets: [['env', {
                useBuiltIns: true,
                targets: {
                  ie: 11
                }
              }]]
            }
          }
        },
        {
          test: /\.scss$/,
          use: [
            { loader: env.production ? MiniCssExtractPlugin.loader : 'style-loader' },
            { loader: "css-loader" },
            {
              loader: "sass-loader",
              options: {
                includePaths: ["node_modules/bootstrap/scss", "node_modules/font-awesome/scss"],
                precision: 8
              }
            }
          ]
        }
      ]
    },
    optimization: {
      minimizer: [
        new UglifyJsPlugin({
          cache: true,
          parallel: true,
          sourceMap: true
        }),
        new OptimizeCSSAssetsPlugin({})
      ]
    },
    plugins: [
      new CopyWebpackPlugin(
        [
          { from: 'static/**/*', to: '../../' }
        ],
        {}
      ),
      new MiniCssExtractPlugin({ filename: "../css/app.css" }),
      new webpack.ProvidePlugin({
        $: 'jquery',
        jQuery: 'jquery',
        'window.jQuery': 'jquery'
      })
    ]

  };
};
