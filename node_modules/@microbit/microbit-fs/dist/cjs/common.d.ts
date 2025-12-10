/**
 * General utilities.
 *
 * (c) 2019 Micro:bit Educational Foundation and the microbit-fs contributors.
 * SPDX-License-Identifier: MIT
 */
/**
 * Converts a string into a byte array of characters.
 * @param str - String to convert to bytes.
 * @returns A byte array with the encoded data.
 */
export declare function strToBytes(str: string): Uint8Array;
/**
 * Converts a byte array into a string of characters.
 * @param byteArray - Array of bytes to convert.
 * @returns String output from the conversion.
 */
export declare function bytesToStr(byteArray: Uint8Array): string;
/**
 * Concatenates two Uint8Arrays.
 *
 * @param first - The first array to concatenate.
 * @param second - The second array to concatenate.
 * @returns New array with both inputs concatenated.
 */
export declare const concatUint8Array: (first: Uint8Array, second: Uint8Array) => Uint8Array<ArrayBufferLike>;
/**
 * Compares two Uint8Array.
 *
 * @param first - The first array to compare.
 * @param second - The second array to compare.
 * @returns Boolean indicating if they are equal.
 */
export declare const areUint8ArraysEqual: (first: Uint8Array, second: Uint8Array) => boolean;
