// Capture the Vela emulator's guest framebuffer via the emulator gRPC service.
//
// The native emulator window paints the 212x520 panel black on this Windows host
// (a host-GL *presentation* defect — the guest renders fine). getScreenshot reads
// the framebuffer server-side, before that broken presentation step, so it always
// returns the real pixels. This is the reliable way to *see* band UI during dev.
//
// Prereqs:
//   - Launch the emulator with a gRPC port, e.g.:
//       emulator.exe -vela -avd Vela_Band10 -gpu swiftshader_indirect -no-snapshot -grpc 8554
//   - Run with band-app's node_modules on the path (it bundles @grpc/*):
//       NODE_PATH=./node_modules node tools/capture-panel.js panel.png
//
// Usage: node tools/capture-panel.js <outfile.png> [PNG|RGBA8888|RGB888] [grpcPort]
const path = require('path');
const fs = require('fs');
const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');

const LIB = 'C:/Users/www/.vela/sdk/emulator/windows-x86_64/lib';
const out = process.argv[2] || 'panel.png';
const fmt = (process.argv[3] || 'PNG').toUpperCase();
const port = process.argv[4] || '8554';

const def = protoLoader.loadSync(path.join(LIB, 'emulator_controller.proto'), {
  keepCase: true, longs: String, enums: String, defaults: true, oneofs: true, includeDirs: [LIB],
});
const pkg = grpc.loadPackageDefinition(def);
const Client = pkg.android.emulation.control.EmulatorController;
const client = new Client('localhost:' + port, grpc.credentials.createInsecure());

client.waitForReady(new Date(Date.now() + 8000), (err) => {
  if (err) { console.error('emulator gRPC not reachable on :' + port, err.message); process.exit(2); }
  client.getScreenshot({ format: fmt, width: 0, height: 0, display: 0 }, (e, img) => {
    if (e) { console.error('getScreenshot failed:', e.message); process.exit(3); }
    const buf = img.image;
    const w = img.format && img.format.width, h = img.format && img.format.height;
    if (!buf || !buf.length) { console.error('empty image — display inactive?'); process.exit(4); }
    fs.writeFileSync(out, buf);
    console.log(`wrote ${out} (${buf.length} bytes, ${w}x${h}, ${fmt})`);
  });
});
