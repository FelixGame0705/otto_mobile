/**
 * Interprets the data stored in the UICR memory space.
 *
 * For more info:
 * https://microbit-micropython.readthedocs.io/en/latest/devguide/hexformat.html
 *
 * (c) 2019 Micro:bit Educational Foundation and the microbit-fs contributors.
 * SPDX-License-Identifier: MIT
 */
import MemoryMap from 'nrf-intel-hex';
import { DeviceMemInfo } from './device-mem-info.js';
/** MicroPython data stored in the UICR Customer area. */
interface MicropythonUicrData extends DeviceMemInfo {
    uicrStartAddress: number;
    uicrEndAddress: number;
}
/**
 * Reads the UICR data from an Intel Hex map and retrieves the MicroPython data.
 *
 * @throws {Error} When the Magic Header is not present.
 *
 * @param intelHexMap - Memory map of the Intel Hex data.
 * @returns Object with the decoded UICR MicroPython data.
 */
declare function getHexMapUicrData(intelHexMap: MemoryMap): MicropythonUicrData;
/**
 * Reads the UICR data from an Intel Hex string and retrieves the MicroPython
 * data.
 *
 * @throws {Error} When the Magic Header is not present.
 *
 * @param intelHex - MicroPython Intel Hex string.
 * @returns Object with the decoded UICR MicroPython data.
 */
declare function getIntelHexUicrData(intelHex: string): MicropythonUicrData;
export { getHexMapUicrData, getIntelHexUicrData };
export type { MicropythonUicrData };
