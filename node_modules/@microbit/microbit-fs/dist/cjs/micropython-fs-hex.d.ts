/**
 * Filesystem management for MicroPython hex files.
 *
 * (c) 2019 Micro:bit Educational Foundation and the microbit-fs contributors.
 * SPDX-License-Identifier: MIT
 */
import * as microbitUh from '@microbit/microbit-universal-hex';
import { FsInterface } from './fs-interface.js';
/**
 * The Board ID is used to identify the different targets from a Universal Hex.
 * In this case the target represents a micro:bit version.
 * For micro:bit V1 (v1.3, v1.3B and v1.5) the `boardId` is `0x9900`, and for
 * V2 `0x9903`.
 * This is being re-exported from the @microbit/microbit-universal-hex package.
 */
export import microbitBoardId = microbitUh.microbitBoardId;
/**
 * Simple interface to pair an Intel Hex string with the board ID it represents.
 */
export interface IntelHexWithId {
    /** Intel Hex string */
    hex: string;
    /** Board ID to identify the Intel Hex and encode inside the Universal Hex */
    boardId: number | microbitBoardId;
}
/**
 * Options for importing Hex files into a MicropythonFsHex instance.
 */
export interface ImportOptions {
    overwrite?: boolean;
    formatFirst?: boolean;
}
/**
 * Manage filesystem files in one or multiple MicroPython hex files.
 *
 * @public
 */
export declare class MicropythonFsHex implements FsInterface {
    private _uPyFsBuilderCache;
    private _files;
    private _storageSize;
    /**
     * File System manager constructor.
     *
     * At the moment it needs a MicroPython hex string without files included.
     * Multiple MicroPython images can be provided to generate a Universal Hex.
     *
     * @throws {Error} When any of the input iHex contains filesystem files.
     * @throws {Error} When any of the input iHex is not a valid MicroPython hex.
     *
     * @param intelHex - MicroPython Intel Hex string or an array of Intel Hex
     *    strings with their respective board IDs.
     */
    constructor(intelHex: string | IntelHexWithId[], { maxFsSize }?: {
        maxFsSize?: number;
    });
    /**
     * Create a new file and add it to the file system.
     *
     * @throws {Error} When the file already exists.
     * @throws {Error} When an invalid filename is provided.
     * @throws {Error} When invalid file data is provided.
     *
     * @param filename - Name for the file.
     * @param content - File content to write.
     */
    create(filename: string, content: string | Uint8Array): void;
    /**
     * Write a file into the file system. Overwrites a previous file with the
     * same name.
     *
     * @throws {Error} When an invalid filename is provided.
     * @throws {Error} When invalid file data is provided.
     *
     * @param filename - Name for the file.
     * @param content - File content to write.
     */
    write(filename: string, content: string | Uint8Array): void;
    append(filename: string, content: string): void;
    /**
     * Read the text from a file.
     *
     * @throws {Error} When invalid file name is provided.
     * @throws {Error} When file is not in the file system.
     *
     * @param filename - Name of the file to read.
     * @returns Text from the file.
     */
    read(filename: string): string;
    /**
     * Read the bytes from a file.
     *
     * @throws {Error} When invalid file name is provided.
     * @throws {Error} When file is not in the file system.
     *
     * @param filename - Name of the file to read.
     * @returns Byte array from the file.
     */
    readBytes(filename: string): Uint8Array;
    /**
     * Delete a file from the file system.
     *
     * @throws {Error} When invalid file name is provided.
     * @throws {Error} When the file doesn't exist.
     *
     * @param filename - Name of the file to delete.
     */
    remove(filename: string): void;
    /**
     * Check if a file is already present in the file system.
     *
     * @param filename - Name for the file to check.
     * @returns True if it exists, false otherwise.
     */
    exists(filename: string): boolean;
    /**
     * Returns the size of a file in bytes.
     *
     * @throws {Error} When invalid file name is provided.
     * @throws {Error} When the file doesn't exist.
     *
     * @param filename - Name for the file to check.
     * @returns Size file size in bytes.
     */
    size(filename: string): number;
    /**
     * @returns A list all the files in the file system.
     */
    ls(): string[];
    /**
     * Sets a storage size limit. Must be smaller than available space in
     * MicroPython.
     *
     * @param {number} size - Size in bytes for the filesystem.
     */
    setStorageSize(size: number): void;
    /**
     * The available filesystem total size either calculated by the MicroPython
     * hex or the max storage size limit has been set.
     *
     * @returns Size of the filesystem in bytes.
     */
    getStorageSize(): number;
    /**
     * @returns The total number of bytes currently used by files in the file system.
     */
    getStorageUsed(): number;
    /**
     * @returns The remaining storage of the file system in bytes.
     */
    getStorageRemaining(): number;
    /**
     * Read the files included in a MicroPython hex string and add them to this
     * instance.
     *
     * @throws {Error} When there are no files to import in the hex.
     * @throws {Error} When there is a problem reading the files from the hex.
     * @throws {Error} When a filename already exists in this instance (all other
     *     files are still imported).
     *
     * @param intelHex - MicroPython hex string with files.
     * @param overwrite - Flag to overwrite existing files in this instance.
     * @param formatFirst - Erase all the previous files before importing. It only
     *     erases the files after there are no error during hex file parsing.
     * @returns A filename list of added files.
     */
    importFilesFromIntelHex(intelHex: string, { overwrite, formatFirst }?: ImportOptions): string[];
    /**
     * Read the files included in a MicroPython Universal Hex string and add them
     * to this instance.
     *
     * @throws {Error} When there are no files to import from one of the hex.
     * @throws {Error} When the files in the individual hex are different.
     * @throws {Error} When there is a problem reading files from one of the hex.
     * @throws {Error} When a filename already exists in this instance (all other
     *     files are still imported).
     *
     * @param universalHex - MicroPython Universal Hex string with files.
     * @param overwrite - Flag to overwrite existing files in this instance.
     * @param formatFirst - Erase all the previous files before importing. It only
     *     erases the files after there are no error during hex file parsing.
     * @returns A filename list of added files.
     */
    importFilesFromUniversalHex(universalHex: string, { overwrite, formatFirst }?: ImportOptions): string[];
    /**
     * Read the files included in a MicroPython Universal or Intel Hex string and
     * add them to this instance.
     *
     * @throws {Error} When there are no files to import from the hex.
     * @throws {Error} When in the Universal Hex the files of the individual hexes
     *    are different.
     * @throws {Error} When there is a problem reading files from one of the hex.
     * @throws {Error} When a filename already exists in this instance (all other
     *     files are still imported).
     *
     * @param hexStr - MicroPython Intel or Universal Hex string with files.
     * @param overwrite - Flag to overwrite existing files in this instance.
     * @param formatFirst - Erase all the previous files before importing. It only
     *     erases the files after there are no error during hex file parsing.
     * @returns A filename list of added files.
     */
    importFilesFromHex(hexStr: string, options?: ImportOptions): string[];
    /**
     * Generate a new copy of the MicroPython Intel Hex with the files in the
     * filesystem included.
     *
     * @throws {Error} When a file doesn't have any data.
     * @throws {Error} When there are issues calculating file system boundaries.
     * @throws {Error} When there is no space left for a file.
     * @throws {Error} When the board ID is not found.
     * @throws {Error} When there are multiple MicroPython hexes and board ID is
     *    not provided.
     *
     * @param boardId - When multiple MicroPython hex files are provided select
     *    one via this argument.
     *
     * @returns A new string with MicroPython and the filesystem included.
     */
    getIntelHex(boardId?: number | microbitBoardId): string;
    /**
     * Generate a byte array of the MicroPython and filesystem data.
     *
     * @throws {Error} When a file doesn't have any data.
     * @throws {Error} When there are issues calculating file system boundaries.
     * @throws {Error} When there is no space left for a file.
     * @throws {Error} When the board ID is not found.
     * @throws {Error} When there are multiple MicroPython hexes and board ID is
     *    not provided.
     *
     * @param boardId - When multiple MicroPython hex files are provided select
     *    one via this argument.
     *
     * @returns A Uint8Array with MicroPython and the filesystem included.
     */
    getIntelHexBytes(boardId?: number | microbitBoardId): Uint8Array;
    /**
     * Generate a new copy of a MicroPython Universal Hex with the files in the
     * filesystem included.
     *
     * @throws {Error} When a file doesn't have any data.
     * @throws {Error} When there are issues calculating file system boundaries.
     * @throws {Error} When there is no space left for a file.
     * @throws {Error} When this method is called without having multiple
     *    MicroPython hexes.
     *
     * @returns A new Universal Hex string with MicroPython and filesystem.
     */
    getUniversalHex(): string;
}
