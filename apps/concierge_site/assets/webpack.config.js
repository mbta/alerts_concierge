const path = require('path');
const { ProvidePlugin } = require('webpack');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const CssMinimizerPlugin = require('css-minimizer-webpack-plugin');
const TerserPlugin = require('terser-webpack-plugin');

module.exports = (env, options) => ({
  optimization: {
    minimizer: [new TerserPlugin(), new CssMinimizerPlugin()]
  },
  entry: {
    app: './js/app.js',
    admin: './js/admin/index.tsx'
  },
  output: {
    path: path.resolve(__dirname, '../priv/static/js')
  },
  resolve: {
    extensions: ['.css', '.scss', '.js', '.json', '.ts', '.tsx']
  },
  module: {
    rules: [
      { test: /\.js$/, exclude: /node_modules/, loader: 'babel-loader' },
      { test: /\.tsx?$/, loader: 'awesome-typescript-loader' },
      {
        test: /\.s?css$/,
        use: [
          MiniCssExtractPlugin.loader,
          { loader: 'css-loader', options: { url: false } },
          {
            loader: 'sass-loader',
            options: { sassOptions: { quietDeps: true } }
          }
        ]
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: '../css/app.css' }),
    new CopyWebpackPlugin({ patterns: [{ from: 'static/', to: '../' }] })
  ]
});
