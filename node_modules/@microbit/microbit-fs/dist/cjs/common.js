"use strict";
/**
 * General utilities.
 *
 * (c) 2019 Micro:bit Educational Foundation and the microbit-fs contributors.
 * SPDX-License-Identifier: MIT
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.areUint8ArraysEqual = exports.concatUint8Array = void 0;
exports.strToBytes = strToBytes;
exports.bytesToStr = bytesToStr;
/**
 * Converts a string into a byte array of characters.
 * @param str - String to convert to bytes.
 * @returns A byte array with the encoded data.
 */
function strToBytes(str) {
    const encoder = new TextEncoder();
    return encoder.encode(str);
}
/**
 * Converts a byte array into a string of characters.
 * @param byteArray - Array of bytes to convert.
 * @returns String output from the conversion.
 */
function bytesToStr(byteArray) {
    const decoder = new TextDecoder();
    return decoder.decode(byteArray);
}
/**
 * Concatenates two Uint8Arrays.
 *
 * @param first - The first array to concatenate.
 * @param second - The second array to concatenate.
 * @returns New array with both inputs concatenated.
 */
const concatUint8Array = (first, second) => {
    const combined = new Uint8Array(first.length + second.length);
    combined.set(first);
    combined.set(second, first.length);
    return combined;
};
exports.concatUint8Array = concatUint8Array;
/**
 * Compares two Uint8Array.
 *
 * @param first - The first array to compare.
 * @param second - The second array to compare.
 * @returns Boolean indicating if they are equal.
 */
const areUint8ArraysEqual = (first, second) => {
    if (first.length !== second.length)
        return false;
    for (let i = 0; i < first.length; i++) {
        if (first[i] !== second[i])
            return false;
    }
    return true;
};
exports.areUint8ArraysEqual = areUint8ArraysEqual;
//# sourceMappingURL=common.js.map