"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SimpleFile = void 0;
/**
 * Class to represent a very simple file.
 *
 * (c) 2019 Micro:bit Educational Foundation and the microbit-fs contributors.
 * SPDX-License-Identifier: MIT
 */
const common_js_1 = require("./common.js");
class SimpleFile {
    /**
     * Create a SimpleFile.
     *
     * @throws {Error} When an invalid filename is provided.
     * @throws {Error} When invalid file data is provided.
     *
     * @param filename - Name for the file.
     * @param data - String or byte array with the file data.
     */
    constructor(filename, data) {
        Object.defineProperty(this, "filename", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        Object.defineProperty(this, "_dataBytes", {
            enumerable: true,
            configurable: true,
            writable: true,
            value: void 0
        });
        if (!filename) {
            throw new Error('File was not provided a valid filename.');
        }
        if (!data) {
            throw new Error(`File ${filename} does not have valid content.`);
        }
        this.filename = filename;
        if (typeof data === 'string') {
            this._dataBytes = (0, common_js_1.strToBytes)(data);
        }
        else if (data instanceof Uint8Array) {
            this._dataBytes = data;
        }
        else {
            throw new Error('File data type must be a string or Uint8Array.');
        }
    }
    getText() {
        return (0, common_js_1.bytesToStr)(this._dataBytes);
    }
    getBytes() {
        return this._dataBytes;
    }
}
exports.SimpleFile = SimpleFile;
//# sourceMappingURL=simple-file.js.map