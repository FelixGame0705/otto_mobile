import { nodeResolve } from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';

export default {
  input: 'src/index.js',
  output: {
    file: 'assets/js/mbfs.bundle.js',
    format: 'iife',
    name: 'MicrobitFsBundle'
  },
  plugins: [
    nodeResolve({
      preferBuiltins: false
    }),
    commonjs()
  ]
};
