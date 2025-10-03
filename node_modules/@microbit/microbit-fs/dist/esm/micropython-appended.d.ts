/**
 * Module to add and remove Python scripts into and from a MicroPython hex.
 *
 * (c) 2019 Micro:bit Educational Foundation and the microbit-fs contributors.
 * SPDX-License-Identifier: MIT
 */
import MemoryMap from 'nrf-intel-hex';
/** User script located at specific flash address. */
declare enum AppendedBlock {
    StartAdd = 253952,
    Length = 8192,
    EndAdd = 262144
}
/**
 * Removes the old insertion line the input Intel Hex string contains it.
 *
 * @param intelHex - String with the intel hex lines.
 * @returns The Intel Hex string without insertion line.
 */
export declare function cleanseOldHexFormat(intelHex: string): string;
/**
 * Parses through an Intel Hex string to find the Python code at the
 * allocated address and extracts it.
 *
 * @param intelHex - Intel Hex block to scan for the code.
 * @return Python code.
 */
declare function getIntelHexAppendedScript(intelHex: string): string;
/**
 * Converts the Python code into the Intel Hex format expected by
 * MicroPython and injects it into a Intel Hex string containing a marker.
 *
 * TODO: Throw error if filesystem is using the penultimate page already.
 *
 * @param intelHex - Single string of Intel Hex records to inject the code.
 * @param pyStr - Python code string.
 * @returns Intel Hex string with the Python code injected.
 */
declare function addIntelHexAppendedScript(intelHex: string, pyCode: string): string;
/**
 * Checks the Intel Hex memory map to see if there is an appended script.
 *
 * @param intelHexMap - Memory map for the MicroPython Intel Hex.
 * @returns True if appended script is present, false otherwise.
 */
declare function isAppendedScriptPresent(intelHex: MemoryMap | string): boolean;
export { AppendedBlock, addIntelHexAppendedScript, getIntelHexAppendedScript, isAppendedScriptPresent, };
