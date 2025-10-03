/**
 * Interprets the Flash Regions Table stored in flash.
 *
 * The micro:bit flash layout is divided in flash regions, each containing a
 * different type of data (Nordic SoftDevice, MicroPython, bootloader, etc).
 * One of the regions is dedicated to the micro:bit filesystem, and this info
 * is used by this library to add the user files into a MicroPython hex File.
 *
 * The Flash Regions Table stores a data table at the end of the last flash page
 * used by the MicroPython runtime.
 * The table contains a series of 16-byte rows with info about each region
 * and it ends with a 16-byte table header with info about the table itself.
 * All in little-endian format.
 *
 * ```
 * |                                                               | Low address
 * | ID| HT|1ST_PAG| REGION_LENGTH | HASH_DATA                     | Row 1
 * | ID| HT|1ST_PAG| REGION_LENGTH | HASH_DATA                     | ...
 * | ID| HT|1ST_PAG| REGION_LENGTH | HASH_DATA                     | Row N
 * | MAGIC_1       | VER   | T_LEN |REG_CNT| P_SIZE| MAGIC_2       | Header
 * |---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---| Page end
 * |0x0|0x1|0x2|0x3|0x4|0x5|0x6|0x7|0x8|0x9|0xa|0xb|0xc|0xd|0xe|0xf|
 * |---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
 * ```
 *
 * More information about how this data is added to the MicroPython Intel Hex
 * file can be found in the MicroPython for micro:bit v2 repository:
 *   https://github.com/microbit-foundation/micropython-microbit-v2/blob/v2.0.0-beta.3/src/addlayouttable.py
 *
 * @packageDocumentation
 *
 * (c) 2020 Micro:bit Educational Foundation and the microbit-fs contributors.
 * SPDX-License-Identifier: MIT
 */
import MemoryMap from 'nrf-intel-hex';
import { DeviceMemInfo } from './device-mem-info.js';
/**
 * Reads the Flash Regions Table data from an Intel Hex map and retrieves the
 * MicroPython DeviceMemInfo data.
 *
 * @throws {Error} When the Magic Header is not present.
 * @throws {Error} When the MicroPython or FS regions are not found.
 *
 * @param intelHexMap - Memory map of the Intel Hex to scan.
 * @returns Object with the parsed data from the Flash Regions Table.
 */
declare function getHexMapFlashRegionsData(iHexMap: MemoryMap): DeviceMemInfo;
/**
 * Reads the Flash Regions Table data from an Intel Hex map and retrieves the
 * MicroPython DeviceMemInfo data.
 *
 * @throws {Error} When the Magic Header is not present.
 * @throws {Error} When the MicroPython or FS regions are not found.
 *
 * @param intelHex - MicroPython Intel Hex string.
 * @returns Object with the parsed data from the Flash Regions Table.
 */
declare function getIntelHexFlashRegionsData(intelHex: string): DeviceMemInfo;
export { getHexMapFlashRegionsData, getIntelHexFlashRegionsData };
