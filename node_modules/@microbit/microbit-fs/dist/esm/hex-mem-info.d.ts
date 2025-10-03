/**
 * Retrieves the device information stored inside a MicroPython hex file.
 *
 * (c) 2020 Micro:bit Educational Foundation and the microbit-fs contributors.
 * SPDX-License-Identifier: MIT
 */
import MemoryMap from 'nrf-intel-hex';
import { DeviceMemInfo, DeviceVersion } from './device-mem-info.js';
/**
 * Attempts to retrieve the device memory data from an MicroPython Intel Hex
 * memory map.
 *
 * @param {MemoryMap} intelHexMap MicroPython Intel Hex memory map to scan.
 * @returns {DeviceMemInfo} Device data.
 */
declare function getHexMapDeviceMemInfo(intelHexMap: MemoryMap): DeviceMemInfo;
/**
 * Attempts to retrieve the device memory data from an MicroPython Intel Hex.
 *
 * @param intelHex - MicroPython Intel Hex string.
 * @returns {DeviceMemInfo} Device data.
 */
declare function getIntelHexDeviceMemInfo(intelHex: string): DeviceMemInfo;
export type { DeviceMemInfo, DeviceVersion };
export { getHexMapDeviceMemInfo, getIntelHexDeviceMemInfo };
