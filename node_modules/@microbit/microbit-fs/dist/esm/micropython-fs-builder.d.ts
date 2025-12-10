/**
 * Builds and reads a micro:bit MicroPython File System from Intel Hex data.
 *
 * Follows this implementation:
 * https://github.com/bbcmicrobit/micropython/blob/v1.0.1/source/microbit/filesystem.c
 *
 * How it works:
 * The File system size is calculated based on the UICR data addded to the
 * MicroPython final hex to determine the limits of the filesystem space.
 * Based on how many space there is available it calculates how many free
 * chunks it can fit, each chunk being of CHUNK_LEN size in bytes.
 * There is one spare page which holds persistent configuration data that is
 * used by MicroPython for bulk erasing, so we also mark it as such here.
 *
 * Each chunk is enumerated with an index number. The first chunk starts with
 * index 1 (as value 0 is reserved to indicate a Freed chunk) at the bottom of
 * the File System (lowest address), and the indexes increase sequentially.
 * Each chunk consists of a one byte marker at the head and a one tail byte.
 * The byte at the tail is a pointer to the next chunk index.
 * The head byte marker is either one of the values in the ChunkMarker enum, to
 * indicate the a special type of chunk, or a pointer to the previous chunk
 * index.
 * The special markers indicate whether the chunk is the start of a file, if it
 * is Unused, if it is Freed (same as unused, but not yet erased) or if this
 * is the start of a flash page used for Persistent Data (bulk erase operation).
 *
 * A file consists of a double linked list of chunks. The first chunk in a
 * file, indicated by the FileStart marker, contains the data end offset for
 * the last chunk and the file name.
 *
 * (c) 2019 Micro:bit Educational Foundation and the microbit-fs contributors.
 * SPDX-License-Identifier: MIT
 */
import MemoryMap from 'nrf-intel-hex';
/** Object to contain cached data for quicker Intel Hex string generation */
interface MpFsBuilderCache {
    originalIntelHex: string;
    originalMemMap: MemoryMap;
    uPyEndAddress: number;
    uPyIntelHex: string;
    fsSize: number;
}
/**
 * To speed up the Intel Hex string generation with MicroPython and the
 * filesystem we can cache some of the Intel Hex records and the parsed Memory
 * Map. This function creates an object with cached data that can then be sent
 * to other functions from this module.
 *
 * @param originalIntelHex Intel Hex string with MicroPython to cache.
 * @returns Cached MpFsBuilderCache object.
 */
declare function createMpFsBuilderCache(originalIntelHex: string): MpFsBuilderCache;
/**
 * @returns Size, in bytes, of how much space the file would take in the
 *     MicroPython filesystem.
 */
declare function calculateFileSize(filename: string, data: Uint8Array): number;
/**
 * Adds a hash table of filenames and byte arrays as files to the MicroPython
 * filesystem.
 *
 * @throws {Error} When the an invalid file name is given.
 * @throws {Error} When a file doesn't have any data.
 * @throws {Error} When there are issues calculating the file system boundaries.
 * @throws {Error} When there is no space left for a file.
 *
 * @param intelHex - MicroPython Intel Hex string or MemoryMap.
 * @param files - Hash table with filenames as the key and byte arrays as the
 *     value.
 * @returns MicroPython Intel Hex string with the files in the filesystem.
 */
declare function addIntelHexFiles(intelHex: string | MemoryMap, files: {
    [filename: string]: Uint8Array;
}, returnBytes?: boolean): string | Uint8Array;
/**
 * Generates an Intel Hex string with MicroPython and files in the filesystem.
 *
 * Uses pre-cached MicroPython memory map and Intel Hex string of record to
 * speed up the Intel Hex generation compared to addIntelHexFiles().
 *
 * @param cache - Object with cached data from createMpFsBuilderCache().
 * @param files - Hash table with filenames as the key and byte arrays as the
 *     value.
 * @returns MicroPython Intel Hex string with the files in the filesystem.
 */
declare function generateHexWithFiles(cache: MpFsBuilderCache, files: {
    [filename: string]: Uint8Array;
}): string;
/**
 * Reads the filesystem included in a MicroPython Intel Hex string or Map.
 *
 * @throws {Error} When multiple files with the same name encountered.
 * @throws {Error} When a file chunk points to an unused chunk.
 * @throws {Error} When a file chunk marker does not point to previous chunk.
 * @throws {Error} When following through the chunks linked list iterates
 *     through more chunks and used chunks (sign of an infinite loop).
 *
 * @param intelHex - The MicroPython Intel Hex string or MemoryMap to read from.
 * @returns Dictionary with the filename as key and byte array as values.
 */
declare function getIntelHexFiles(intelHex: string | MemoryMap): {
    [filename: string]: Uint8Array;
};
/**
 * Calculate the MicroPython filesystem size.
 *
 * @param intelHexMap - The MicroPython Intel Hex Memory Map.
 * @returns Size of the filesystem in bytes.
 */
declare function getMemMapFsSize(intelHexMap: MemoryMap): number;
export type { MpFsBuilderCache };
export { createMpFsBuilderCache, addIntelHexFiles, generateHexWithFiles, calculateFileSize, getIntelHexFiles, getMemMapFsSize, };
