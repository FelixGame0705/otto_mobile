// Import microbit-fs library
import { MicropythonFsHex, microbitBoardId } from "@microbit/microbit-fs";

/**
 * Build Universal Hex from V1 and V2 firmware with Python code
 * @param {string} v1Hex - V1 firmware hex content
 * @param {string} v2Hex - V2 firmware hex content  
 * @param {string} mainPy - Python code to embed
 * @returns {string} Universal Hex content
 */
export function buildUniversalHex(v1Hex, v2Hex, mainPy) {
  try {
    // Create filesystem with both V1 and V2 firmware
    const fs = new MicropythonFsHex([
      { hex: v1Hex, boardId: microbitBoardId.V1 },
      { hex: v2Hex, boardId: microbitBoardId.V2 },
    ]);
    
    // Write the Python code to main.py
    fs.write("main.py", mainPy);
    
    // Generate Universal Hex
    return fs.getUniversalHex();
  } catch (error) {
    throw new Error(`Failed to build Universal Hex: ${error.message}`);
  }
}

/**
 * Validate hex content
 * @param {string} hex - Hex content to validate
 * @returns {boolean} True if valid hex format
 */
export function validateHex(hex) {
  if (!hex || typeof hex !== 'string') {
    return false;
  }
  
  // Check if it starts with Intel HEX record format
  const lines = hex.split('\n').filter(line => line.trim());
  if (lines.length === 0) {
    return false;
  }
  
  // Check first line starts with ':'
  const firstLine = lines[0].trim();
  if (!firstLine.startsWith(':')) {
    return false;
  }
  
  return true;
}

/**
 * Get estimated Universal Hex size
 * @param {string} v1Hex - V1 firmware hex
 * @param {string} v2Hex - V2 firmware hex
 * @param {string} mainPy - Python code
 * @returns {number} Estimated size in bytes
 */
export function getEstimatedSize(v1Hex, v2Hex, mainPy) {
  const v1Size = v1Hex ? v1Hex.length : 0;
  const v2Size = v2Hex ? v2Hex.length : 0;
  const pySize = mainPy ? mainPy.length : 0;
  
  // Universal Hex is typically 1.7-1.9MB
  // This is a rough estimation
  return Math.max(v1Size, v2Size) + pySize + 100000; // Add overhead
}
