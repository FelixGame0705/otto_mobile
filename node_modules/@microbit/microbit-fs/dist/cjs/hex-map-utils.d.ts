import MemoryMap from 'nrf-intel-hex';
/**
 * Reads a 64 bit little endian number from an Intel Hex memory map.
 *
 * Any missing data in that address range that is not contained inside the
 * MemoryMap is filled with 0xFF.
 *
 * @param intelHexMap - Memory map of the Intel Hex data.
 * @param address - Start address of the 32 bit number.
 * @returns Number with the unsigned integer representation of those 8 bytes.
 */
export declare function getUint64(intelHexMap: MemoryMap, address: number): number;
/**
 * Reads a 32 bit little endian number from an Intel Hex memory map.
 *
 * Any missing data in that address range that is not contained inside the
 * MemoryMap is filled with 0xFF.
 *
 * @param intelHexMap - Memory map of the Intel Hex data.
 * @param address - Start address of the 32 bit number.
 * @returns Number with the unsigned integer representation of those 4 bytes.
 */
export declare function getUint32(intelHexMap: MemoryMap, address: number): number;
/**
 * Reads a 16 bit little endian number from an Intel Hex memory map.
 *
 * Any missing data in that address range that is not contained inside the
 * MemoryMap is filled with 0xFF.
 *
 * @param intelHexMap - Memory map of the Intel Hex data.
 * @param address - Start address of the 16 bit number.
 * @returns Number with the unsigned integer representation of those 2 bytes.
 */
export declare function getUint16(intelHexMap: MemoryMap, address: number): number;
/**
 * Reads a 8 bit number from an Intel Hex memory map.
 *
 * If the data is not contained inside the MemoryMap it returns 0xFF.
 *
 * @param intelHexMap - Memory map of the Intel Hex data.
 * @param address - Start address of the 16 bit number.
 * @returns Number with the unsigned integer representation of those 2 bytes.
 */
export declare function getUint8(intelHexMap: MemoryMap, address: number): number;
/**
 * Decodes a UTF-8 null terminated string stored in the Intel Hex data at
 * the indicated address.
 *
 * @param intelHexMap - Memory map of the Intel Hex data.
 * @param address - Start address for the string.
 * @returns String read from the Intel Hex data.
 */
export declare function getString(intelHexMap: MemoryMap, address: number): string;
