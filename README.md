# Otto Mobile

Flutter app with two main screens:

- BlocklyEditorScreen: author programs using Blockly, view Python preview, export JSON.
- PhaserRunnerScreen: opens `https://phaser-map-seven.vercel.app/` in WebView and receives compiled JSON via bridge.

## Features

- WebView-based Blockly editor (`assets/blockly/index.html`) with custom blocks and generators
- CompilerService validates schema and produces Python preview (display-only)
- Storage via SharedPreferences + JSON import/export via file_picker
- Phaser runner bridge sends messages via `window.receiveFromFlutter` or `CustomEvent('OttobitProgram')`

## Run

1. `flutter pub get`
2. Run on Android/iOS/desktop. Navigate:
   - `/blockly` to open the editor
   - `/phaser` to open the runner
3. In editor: Compose blocks → Compile → Export JSON or Send to Phaser
4. In runner: Use AppBar action "Send Sample" to verify bridge (see console logs)

## Screenshots

Add screenshots here.

## Notes

- JavaScriptMode is unrestricted for WebView
- Logs are printed in Flutter and injected JS console for debugging
