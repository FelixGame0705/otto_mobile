"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getHexMapDeviceMemInfo = getHexMapDeviceMemInfo;
exports.getIntelHexDeviceMemInfo = getIntelHexDeviceMemInfo;
/**
 * Retrieves the device information stored inside a MicroPython hex file.
 *
 * (c) 2020 Micro:bit Educational Foundation and the microbit-fs contributors.
 * SPDX-License-Identifier: MIT
 */
const nrf_intel_hex_1 = __importDefault(require("nrf-intel-hex"));
const flashRegions = __importStar(require("./flash-regions.js"));
const uicr = __importStar(require("./uicr.js"));
/**
 * Attempts to retrieve the device memory data from an MicroPython Intel Hex
 * memory map.
 *
 * @param {MemoryMap} intelHexMap MicroPython Intel Hex memory map to scan.
 * @returns {DeviceMemInfo} Device data.
 */
function getHexMapDeviceMemInfo(intelHexMap) {
    let errorMsg = '';
    try {
        return uicr.getHexMapUicrData(intelHexMap);
    }
    catch (err) {
        errorMsg += err.message + '\n';
    }
    try {
        return flashRegions.getHexMapFlashRegionsData(intelHexMap);
    }
    catch (err) {
        throw new Error(errorMsg + err.message);
    }
}
/**
 * Attempts to retrieve the device memory data from an MicroPython Intel Hex.
 *
 * @param intelHex - MicroPython Intel Hex string.
 * @returns {DeviceMemInfo} Device data.
 */
function getIntelHexDeviceMemInfo(intelHex) {
    return getHexMapDeviceMemInfo(nrf_intel_hex_1.default.fromHex(intelHex));
}
//# sourceMappingURL=hex-mem-info.js.map