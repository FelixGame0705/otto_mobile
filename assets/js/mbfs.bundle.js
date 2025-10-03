var MicrobitFsBundle = (function (exports) {
    'use strict';

    /**
     * Parser/writer for the "Intel hex" format.
     */

    /*
     * A regexp that matches lines in a .hex file.
     *
     * One hexadecimal character is matched by "[0-9A-Fa-f]".
     * Two hex characters are matched by "[0-9A-Fa-f]{2}"
     * Eight or more hex characters are matched by "[0-9A-Fa-f]{8,}"
     * A capture group of two hex characters is "([0-9A-Fa-f]{2})"
     *
     * Record mark         :
     * 8 or more hex chars  ([0-9A-Fa-f]{8,})
     * Checksum                              ([0-9A-Fa-f]{2})
     * Optional newline                                      (?:\r\n|\r|\n|)
     */
    const hexLineRegexp = /:([0-9A-Fa-f]{8,})([0-9A-Fa-f]{2})(?:\r\n|\r|\n|)/g;


    // Takes a Uint8Array as input,
    // Returns an integer in the 0-255 range.
    function checksum(bytes) {
        return (-bytes.reduce((sum, v)=>sum + v, 0)) & 0xFF;
    }

    // Takes two Uint8Arrays as input,
    // Returns an integer in the 0-255 range.
    function checksumTwo(array1, array2) {
        const partial1 = array1.reduce((sum, v)=>sum + v, 0);
        const partial2 = array2.reduce((sum, v)=>sum + v, 0);
        return -( partial1 + partial2 ) & 0xFF;
    }


    // Trivial utility. Converts a number to hex and pads with zeroes up to 2 characters.
    function hexpad(number) {
        return number.toString(16).toUpperCase().padStart(2, '0');
    }


    // Polyfill as per https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isInteger
    Number.isInteger = Number.isInteger || function(value) {
        return typeof value === 'number' &&
        isFinite(value) &&
        Math.floor(value) === value;
    };


    /**
     * @class MemoryMap
     *
     * Represents the contents of a memory layout, with main focus into (possibly sparse) blocks of data.
     *<br/>
     * A {@linkcode MemoryMap} acts as a subclass of
     * {@linkcode https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Map|Map}.
     * In every entry of it, the key is the starting address of a data block (an integer number),
     * and the value is the <tt>Uint8Array</tt> with the data for that block.
     *<br/>
     * The main rationale for this is that a .hex file can contain a single block of contiguous
     * data starting at memory address 0 (and it's the common case for simple .hex files),
     * but complex files with several non-contiguous data blocks are also possible, thus
     * the need for a data structure on top of the <tt>Uint8Array</tt>s.
     *<br/>
     * In order to parse <tt>.hex</tt> files, use the {@linkcode MemoryMap.fromHex} <em>static</em> factory
     * method. In order to write <tt>.hex</tt> files, create a new {@linkcode MemoryMap} and call
     * its {@linkcode MemoryMap.asHexString} method.
     *
     * @extends Map
     * @example
     * import MemoryMap from 'nrf-intel-hex';
     *
     * let memMap1 = new MemoryMap();
     * let memMap2 = new MemoryMap([[0, new Uint8Array(1,2,3,4)]]);
     * let memMap3 = new MemoryMap({0: new Uint8Array(1,2,3,4)});
     * let memMap4 = new MemoryMap({0xCF0: new Uint8Array(1,2,3,4)});
     */
    class MemoryMap {
        /**
         * @param {Iterable} blocks The initial value for the memory blocks inside this
         * <tt>MemoryMap</tt>. All keys must be numeric, and all values must be instances of
         * <tt>Uint8Array</tt>. Optionally it can also be a plain <tt>Object</tt> with
         * only numeric keys.
         */
        constructor(blocks) {
            this._blocks = new Map();

            if (blocks && typeof blocks[Symbol.iterator] === 'function') {
                for (const tuple of blocks) {
                    if (!(tuple instanceof Array) || tuple.length !== 2) {
                        throw new Error('First parameter to MemoryMap constructor must be an iterable of [addr, bytes] or undefined');
                    }
                    this.set(tuple[0], tuple[1]);
                }
            } else if (typeof blocks === 'object') {
                // Try iterating through the object's keys
                const addrs = Object.keys(blocks);
                for (const addr of addrs) {
                    this.set(parseInt(addr), blocks[addr]);
                }

            } else if (blocks !== undefined && blocks !== null) {
                throw new Error('First parameter to MemoryMap constructor must be an iterable of [addr, bytes] or undefined');
            }
        }

        set(addr, value) {
            if (!Number.isInteger(addr)) {
                throw new Error('Address passed to MemoryMap is not an integer');
            }
            if (addr < 0) {
                throw new Error('Address passed to MemoryMap is negative');
            }
            if (!(value instanceof Uint8Array)) {
                throw new Error('Bytes passed to MemoryMap are not an Uint8Array');
            }
            return this._blocks.set(addr, value);
        }
        // Delegate the following to the 'this._blocks' Map:
        get(addr)    { return this._blocks.get(addr);    }
        clear()      { return this._blocks.clear();      }
        delete(addr) { return this._blocks.delete(addr); }
        entries()    { return this._blocks.entries();    }
        forEach(callback, that) { return this._blocks.forEach(callback, that); }
        has(addr)    { return this._blocks.has(addr);    }
        keys()       { return this._blocks.keys();       }
        values()     { return this._blocks.values();     }
        get size()   { return this._blocks.size;         }
        [Symbol.iterator]() { return this._blocks[Symbol.iterator](); }


        /**
         * Parses a string containing data formatted in "Intel HEX" format, and
         * returns an instance of {@linkcode MemoryMap}.
         *<br/>
         * The insertion order of keys in the {@linkcode MemoryMap} is guaranteed to be strictly
         * ascending. In other words, when iterating through the {@linkcode MemoryMap}, the addresses
         * will be ordered in ascending order.
         *<br/>
         * The parser has an opinionated behaviour, and will throw a descriptive error if it
         * encounters some malformed input. Check the project's
         * {@link https://github.com/NordicSemiconductor/nrf-intel-hex#Features|README file} for details.
         *<br/>
         * If <tt>maxBlockSize</tt> is given, any contiguous data block larger than that will
         * be split in several blocks.
         *
         * @param {String} hexText The contents of a .hex file.
         * @param {Number} [maxBlockSize=Infinity] Maximum size of the returned <tt>Uint8Array</tt>s.
         *
         * @return {MemoryMap}
         *
         * @example
         * import MemoryMap from 'nrf-intel-hex';
         *
         * let intelHexString =
         *     ":100000000102030405060708090A0B0C0D0E0F1068\n" +
         *     ":00000001FF";
         *
         * let memMap = MemoryMap.fromHex(intelHexString);
         *
         * for (let [address, dataBlock] of memMap) {
         *     console.log('Data block at ', address, ', bytes: ', dataBlock);
         * }
         */
        static fromHex(hexText, maxBlockSize = Infinity) {
            const blocks = new MemoryMap();

            let lastCharacterParsed = 0;
            let matchResult;
            let recordCount = 0;

            // Upper Linear Base Address, the 16 most significant bits (2 bytes) of
            // the current 32-bit (4-byte) address
            // In practice this is a offset that is summed to the "load offset" of the
            // data records
            let ulba = 0;

            hexLineRegexp.lastIndex = 0; // Reset the regexp, if not it would skip content when called twice

            while ((matchResult = hexLineRegexp.exec(hexText)) !== null) {
                recordCount++;

                // By default, a regexp loop ignores gaps between matches, but
                // we want to be aware of them.
                if (lastCharacterParsed !== matchResult.index) {
                    throw new Error(
                        'Malformed hex file: Could not parse between characters ' +
                        lastCharacterParsed +
                        ' and ' +
                        matchResult.index +
                        ' ("' +
                        hexText.substring(lastCharacterParsed, Math.min(matchResult.index, lastCharacterParsed + 16)).trim() +
                        '")');
                }
                lastCharacterParsed = hexLineRegexp.lastIndex;

                // Give pretty names to the match's capture groups
                const [, recordStr, recordChecksum] = matchResult;

                // String to Uint8Array - https://stackoverflow.com/questions/43131242/how-to-convert-a-hexademical-string-of-data-to-an-arraybuffer-in-javascript
                const recordBytes = new Uint8Array(recordStr.match(/[\da-f]{2}/gi).map((h)=>parseInt(h, 16)));

                const recordLength = recordBytes[0];
                if (recordLength + 4 !== recordBytes.length) {
                    throw new Error('Mismatched record length at record ' + recordCount + ' (' + matchResult[0].trim() + '), expected ' + (recordLength) + ' data bytes but actual length is ' + (recordBytes.length - 4));
                }

                const cs = checksum(recordBytes);
                if (parseInt(recordChecksum, 16) !== cs) {
                    throw new Error('Checksum failed at record ' + recordCount + ' (' + matchResult[0].trim() + '), should be ' + cs.toString(16) );
                }

                const offset = (recordBytes[1] << 8) + recordBytes[2];
                const recordType = recordBytes[3];
                const data = recordBytes.subarray(4);

                if (recordType === 0) {
                    // Data record, contains data
                    // Create a new block, at (upper linear base address + offset)
                    if (blocks.has(ulba + offset)) {
                        throw new Error('Duplicated data at record ' + recordCount + ' (' + matchResult[0].trim() + ')');
                    }
                    if (offset + data.length > 0x10000) {
                        throw new Error(
                            'Data at record ' +
                            recordCount +
                            ' (' +
                            matchResult[0].trim() +
                            ') wraps over 0xFFFF. This would trigger ambiguous behaviour. Please restructure your data so that for every record the data offset plus the data length do not exceed 0xFFFF.');
                    }

                    blocks.set( ulba + offset, data );

                } else {

                    // All non-data records must have a data offset of zero
                    if (offset !== 0) {
                        throw new Error('Record ' + recordCount + ' (' + matchResult[0].trim() + ') must have 0000 as data offset.');
                    }

                    switch (recordType) {
                    case 1: // EOF
                        if (lastCharacterParsed !== hexText.length) {
                            // This record should be at the very end of the string
                            throw new Error('There is data after an EOF record at record ' + recordCount);
                        }

                        return blocks.join(maxBlockSize);

                    case 2: // Extended Segment Address Record
                        // Sets the 16 most significant bits of the 20-bit Segment Base
                        // Address for the subsequent data.
                        ulba = ((data[0] << 8) + data[1]) << 4;
                        break;

                    case 3: // Start Segment Address Record
                        // Do nothing. Record type 3 only applies to 16-bit Intel CPUs,
                        // where it should reset the program counter (CS+IP CPU registers)
                        break;

                    case 4: // Extended Linear Address Record
                        // Sets the 16 most significant (upper) bits of the 32-bit Linear Address
                        // for the subsequent data
                        ulba = ((data[0] << 8) + data[1]) << 16;
                        break;

                    case 5: // Start Linear Address Record
                        // Do nothing. Record type 5 only applies to 32-bit Intel CPUs,
                        // where it should reset the program counter (EIP CPU register)
                        // It might have meaning for other CPU architectures
                        // (see http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.faqs/ka9903.html )
                        // but will be ignored nonetheless.
                        break;
                    default:
                        throw new Error('Invalid record type 0x' + hexpad(recordType) + ' at record ' + recordCount + ' (should be between 0x00 and 0x05)');
                    }
                }
            }

            if (recordCount) {
                throw new Error('No EOF record at end of file');
            } else {
                throw new Error('Malformed .hex file, could not parse any registers');
            }
        }


        /**
         * Returns a <strong>new</strong> instance of {@linkcode MemoryMap}, containing
         * the same data, but concatenating together those memory blocks that are adjacent.
         *<br/>
         * The insertion order of keys in the {@linkcode MemoryMap} is guaranteed to be strictly
         * ascending. In other words, when iterating through the {@linkcode MemoryMap}, the addresses
         * will be ordered in ascending order.
         *<br/>
         * If <tt>maxBlockSize</tt> is given, blocks will be concatenated together only
         * until the joined block reaches this size in bytes. This means that the output
         * {@linkcode MemoryMap} might have more entries than the input one.
         *<br/>
         * If there is any overlap between blocks, an error will be thrown.
         *<br/>
         * The returned {@linkcode MemoryMap} will use newly allocated memory.
         *
         * @param {Number} [maxBlockSize=Infinity] Maximum size of the <tt>Uint8Array</tt>s in the
         * returned {@linkcode MemoryMap}.
         *
         * @return {MemoryMap}
         */
        join(maxBlockSize = Infinity) {

            // First pass, create a Map of address→length of contiguous blocks
            const sortedKeys = Array.from(this.keys()).sort((a,b)=>a-b);
            const blockSizes = new Map();
            let lastBlockAddr = -1;
            let lastBlockEndAddr = -1;

            for (let i=0,l=sortedKeys.length; i<l; i++) {
                const blockAddr = sortedKeys[i];
                const blockLength = this.get(sortedKeys[i]).length;

                if (lastBlockEndAddr === blockAddr && (lastBlockEndAddr - lastBlockAddr) < maxBlockSize) {
                    // Grow when the previous end address equals the current,
                    // and we don't go over the maximum block size.
                    blockSizes.set(lastBlockAddr, blockSizes.get(lastBlockAddr) + blockLength);
                    lastBlockEndAddr += blockLength;
                } else if (lastBlockEndAddr <= blockAddr) {
                    // Else mark a new block.
                    blockSizes.set(blockAddr, blockLength);
                    lastBlockAddr = blockAddr;
                    lastBlockEndAddr = blockAddr + blockLength;
                } else {
                    throw new Error('Overlapping data around address 0x' + blockAddr.toString(16));
                }
            }

            // Second pass: allocate memory for the contiguous blocks and copy data around.
            const mergedBlocks = new MemoryMap();
            let mergingBlock;
            let mergingBlockAddr = -1;
            for (let i=0,l=sortedKeys.length; i<l; i++) {
                const blockAddr = sortedKeys[i];
                if (blockSizes.has(blockAddr)) {
                    mergingBlock = new Uint8Array(blockSizes.get(blockAddr));
                    mergedBlocks.set(blockAddr, mergingBlock);
                    mergingBlockAddr = blockAddr;
                }
                mergingBlock.set(this.get(blockAddr), blockAddr - mergingBlockAddr);
            }

            return mergedBlocks;
        }

        /**
         * Given a {@link https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Map|<tt>Map</tt>}
         * of {@linkcode MemoryMap}s, indexed by a alphanumeric ID,
         * returns a <tt>Map</tt> of address to tuples (<tt>Arrays</tt>s of length 2) of the form
         * <tt>(id, Uint8Array)</tt>s.
         *<br/>
         * The scenario for using this is having several {@linkcode MemoryMap}s, from several calls to
         * {@link module:nrf-intel-hex~hexToArrays|hexToArrays}, each having a different identifier.
         * This function locates where those memory block sets overlap, and returns a <tt>Map</tt>
         * containing addresses as keys, and arrays as values. Each array will contain 1 or more
         * <tt>(id, Uint8Array)</tt> tuples: the identifier of the memory block set that has
         * data in that region, and the data itself. When memory block sets overlap, there will
         * be more than one tuple.
         *<br/>
         * The <tt>Uint8Array</tt>s in the output are
         * {@link https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/TypedArray/subarray|subarrays}
         * of the input data; new memory is <strong>not</strong> allocated for them.
         *<br/>
         * The insertion order of keys in the output <tt>Map</tt> is guaranteed to be strictly
         * ascending. In other words, when iterating through the <tt>Map</tt>, the addresses
         * will be ordered in ascending order.
         *<br/>
         * When two blocks overlap, the corresponding array of tuples will have the tuples ordered
         * in the insertion order of the input <tt>Map</tt> of block sets.
         *<br/>
         *
         * @param {Map.MemoryMap} memoryMaps The input memory block sets
         *
         * @example
         * import MemoryMap from 'nrf-intel-hex';
         *
         * let memMap1 = MemoryMap.fromHex( hexdata1 );
         * let memMap2 = MemoryMap.fromHex( hexdata2 );
         * let memMap3 = MemoryMap.fromHex( hexdata3 );
         *
         * let maps = new Map([
         *  ['file A', blocks1],
         *  ['file B', blocks2],
         *  ['file C', blocks3]
         * ]);
         *
         * let overlappings = MemoryMap.overlapMemoryMaps(maps);
         *
         * for (let [address, tuples] of overlappings) {
         *     // if 'tuples' has length > 1, there is an overlap starting at 'address'
         *
         *     for (let [address, tuples] of overlappings) {
         *         let [id, bytes] = tuple;
         *         // 'id' in this example is either 'file A', 'file B' or 'file C'
         *     }
         * }
         * @return {Map.Array<mixed,Uint8Array>} The map of possibly overlapping memory blocks
         */
        static overlapMemoryMaps(memoryMaps) {
            // First pass: create a list of addresses where any block starts or ends.
            const cuts = new Set();
            for (const [, blocks] of memoryMaps) {
                for (const [address, block] of blocks) {
                    cuts.add(address);
                    cuts.add(address + block.length);
                }
            }

            const orderedCuts = Array.from(cuts.values()).sort((a,b)=>a-b);
            const overlaps = new Map();

            // Second pass: iterate through the cuts, get slices of every intersecting blockset
            for (let i=0, l=orderedCuts.length-1; i<l; i++) {
                const cut = orderedCuts[i];
                const nextCut = orderedCuts[i+1];
                const tuples = [];

                for (const [setId, blocks] of memoryMaps) {
                    // Find the block with the highest address that is equal or lower to
                    // the current cut (if any)
                    const blockAddr = Array.from(blocks.keys()).reduce((acc, val)=>{
                        if (val > cut) {
                            return acc;
                        }
                        return Math.max( acc, val );
                    }, -1);

                    if (blockAddr !== -1) {
                        const block = blocks.get(blockAddr);
                        const subBlockStart = cut - blockAddr;
                        const subBlockEnd = nextCut - blockAddr;

                        if (subBlockStart < block.length) {
                            tuples.push([ setId, block.subarray(subBlockStart, subBlockEnd) ]);
                        }
                    }
                }

                if (tuples.length) {
                    overlaps.set(cut, tuples);
                }
            }

            return overlaps;
        }


        /**
         * Given the output of the {@linkcode MemoryMap.overlapMemoryMaps|overlapMemoryMaps}
         * (a <tt>Map</tt> of address to an <tt>Array</tt> of <tt>(id, Uint8Array)</tt> tuples),
         * returns a {@linkcode MemoryMap}. This discards the IDs in the process.
         *<br/>
         * The output <tt>Map</tt> contains as many entries as the input one (using the same addresses
         * as keys), but the value for each entry will be the <tt>Uint8Array</tt> of the <b>last</b>
         * tuple for each address in the input data.
         *<br/>
         * The scenario is wanting to join together several parsed .hex files, not worrying about
         * their overlaps.
         *<br/>
         *
         * @param {Map.Array<mixed,Uint8Array>} overlaps The (possibly overlapping) input memory blocks
         * @return {MemoryMap} The flattened memory blocks
         */
        static flattenOverlaps(overlaps) {
            return new MemoryMap(
                Array.from(overlaps.entries()).map(([address, tuples]) => {
                    return [address, tuples[tuples.length - 1][1] ];
                })
            );
        }


        /**
         * Returns a new instance of {@linkcode MemoryMap}, where:
         *
         * <ul>
         *  <li>Each key (the start address of each <tt>Uint8Array</tt>) is a multiple of
         *    <tt>pageSize</tt></li>
         *  <li>The size of each <tt>Uint8Array</tt> is exactly <tt>pageSize</tt></li>
         *  <li>Bytes from the input map to bytes in the output</li>
         *  <li>Bytes not in the input are replaced by a padding value</li>
         * </ul>
         *<br/>
         * The scenario is wanting to prepare pages of bytes for a write operation, where the write
         * operation affects a whole page/sector at once.
         *<br/>
         * The insertion order of keys in the output {@linkcode MemoryMap} is guaranteed
         * to be strictly ascending. In other words, when iterating through the
         * {@linkcode MemoryMap}, the addresses will be ordered in ascending order.
         *<br/>
         * The <tt>Uint8Array</tt>s in the output will be newly allocated.
         *<br/>
         *
         * @param {Number} [pageSize=1024] The size of the output pages, in bytes
         * @param {Number} [pad=0xFF] The byte value to use for padding
         * @return {MemoryMap}
         */
        paginate( pageSize=1024, pad=0xFF) {
            if (pageSize <= 0) {
                throw new Error('Page size must be greater than zero');
            }
            const outPages = new MemoryMap();
            let page;

            const sortedKeys = Array.from(this.keys()).sort((a,b)=>a-b);

            for (let i=0,l=sortedKeys.length; i<l; i++) {
                const blockAddr = sortedKeys[i];
                const block = this.get(blockAddr);
                const blockLength = block.length;
                const blockEnd = blockAddr + blockLength;

                for (let pageAddr = blockAddr - (blockAddr % pageSize); pageAddr < blockEnd; pageAddr += pageSize) {
                    page = outPages.get(pageAddr);
                    if (!page) {
                        page = new Uint8Array(pageSize);
                        page.fill(pad);
                        outPages.set(pageAddr, page);
                    }

                    const offset = pageAddr - blockAddr;
                    let subBlock;
                    if (offset <= 0) {
                        // First page which intersects the block
                        subBlock = block.subarray(0, Math.min(pageSize + offset, blockLength));
                        page.set(subBlock, -offset);
                    } else {
                        // Any other page which intersects the block
                        subBlock = block.subarray(offset, offset + Math.min(pageSize, blockLength - offset));
                        page.set(subBlock, 0);
                    }
                }
            }

            return outPages;
        }


        /**
         * Locates the <tt>Uint8Array</tt> which contains the given offset,
         * and returns the four bytes held at that offset, as a 32-bit unsigned integer.
         *
         *<br/>
         * Behaviour is similar to {@linkcode https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/DataView/getUint32|DataView.prototype.getUint32},
         * except that this operates over a {@linkcode MemoryMap} instead of
         * over an <tt>ArrayBuffer</tt>, and that this may return <tt>undefined</tt> if
         * the address is not <em>entirely</em> contained within one of the <tt>Uint8Array</tt>s.
         *<br/>
         *
         * @param {Number} offset The memory offset to read the data
         * @param {Boolean} [littleEndian=false] Whether to fetch the 4 bytes as a little- or big-endian integer
         * @return {Number|undefined} An unsigned 32-bit integer number
         */
        getUint32(offset, littleEndian) {
            const keys = Array.from(this.keys());

            for (let i=0,l=keys.length; i<l; i++) {
                const blockAddr = keys[i];
                const block = this.get(blockAddr);
                const blockLength = block.length;
                const blockEnd = blockAddr + blockLength;

                if (blockAddr <= offset && (offset+4) <= blockEnd) {
                    return (new DataView(block.buffer, offset - blockAddr, 4)).getUint32(0, littleEndian);
                }
            }
            return;
        }


        /**
         * Returns a <tt>String</tt> of text representing a .hex file.
         * <br/>
         * The writer has an opinionated behaviour. Check the project's
         * {@link https://github.com/NordicSemiconductor/nrf-intel-hex#Features|README file} for details.
         *
         * @param {Number} [lineSize=16] Maximum number of bytes to be encoded in each data record.
         * Must have a value between 1 and 255, as per the specification.
         *
         * @return {String} String of text with the .hex representation of the input binary data
         *
         * @example
         * import MemoryMap from 'nrf-intel-hex';
         *
         * let memMap = new MemoryMap();
         * let bytes = new Uint8Array(....);
         * memMap.set(0x0FF80000, bytes); // The block with 'bytes' will start at offset 0x0FF80000
         *
         * let string = memMap.asHexString();
         */
        asHexString(lineSize = 16) {
            let lowAddress  = 0;    // 16 least significant bits of the current addr
            let highAddress = -1 << 16; // 16 most significant bits of the current addr
            const records = [];
            if (lineSize <=0) {
                throw new Error('Size of record must be greater than zero');
            } else if (lineSize > 255) {
                throw new Error('Size of record must be less than 256');
            }

            // Placeholders
            const offsetRecord = new Uint8Array(6);
            const recordHeader = new Uint8Array(4);

            const sortedKeys = Array.from(this.keys()).sort((a,b)=>a-b);
            for (let i=0,l=sortedKeys.length; i<l; i++) {
                const blockAddr = sortedKeys[i];
                const block = this.get(blockAddr);

                // Sanity checks
                if (!(block instanceof Uint8Array)) {
                    throw new Error('Block at offset ' + blockAddr + ' is not an Uint8Array');
                }
                if (blockAddr < 0) {
                    throw new Error('Block at offset ' + blockAddr + ' has a negative thus invalid address');
                }
                const blockSize = block.length;
                if (!blockSize) { continue; }   // Skip zero-length blocks


                if (blockAddr > (highAddress + 0xFFFF)) {
                    // Insert a new 0x04 record to jump to a new 64KiB block

                    // Round up the least significant 16 bits - no bitmasks because they trigger
                    // base-2 negative numbers, whereas subtracting the modulo maintains precision
                    highAddress = blockAddr - blockAddr % 0x10000;
                    lowAddress = 0;

                    offsetRecord[0] = 2;    // Length
                    offsetRecord[1] = 0;    // Load offset, high byte
                    offsetRecord[2] = 0;    // Load offset, low byte
                    offsetRecord[3] = 4;    // Record type
                    offsetRecord[4] = highAddress >> 24;    // new address offset, high byte
                    offsetRecord[5] = highAddress >> 16;    // new address offset, low byte

                    records.push(
                        ':' +
                        Array.prototype.map.call(offsetRecord, hexpad).join('') +
                        hexpad(checksum(offsetRecord))
                    );
                }

                if (blockAddr < (highAddress + lowAddress)) {
                    throw new Error(
                        'Block starting at 0x' +
                        blockAddr.toString(16) +
                        ' overlaps with a previous block.');
                }

                lowAddress = blockAddr % 0x10000;
                let blockOffset = 0;
                const blockEnd = blockAddr + blockSize;
                if (blockEnd > 0xFFFFFFFF) {
                    throw new Error('Data cannot be over 0xFFFFFFFF');
                }

                // Loop for every 64KiB memory segment that spans this block
                while (highAddress + lowAddress < blockEnd) {

                    if (lowAddress > 0xFFFF) {
                        // Insert a new 0x04 record to jump to a new 64KiB block
                        highAddress += 1 << 16; // Increase by one
                        lowAddress = 0;

                        offsetRecord[0] = 2;    // Length
                        offsetRecord[1] = 0;    // Load offset, high byte
                        offsetRecord[2] = 0;    // Load offset, low byte
                        offsetRecord[3] = 4;    // Record type
                        offsetRecord[4] = highAddress >> 24;    // new address offset, high byte
                        offsetRecord[5] = highAddress >> 16;    // new address offset, low byte

                        records.push(
                            ':' +
                            Array.prototype.map.call(offsetRecord, hexpad).join('') +
                            hexpad(checksum(offsetRecord))
                        );
                    }

                    let recordSize = -1;
                    // Loop for every record for that spans the current 64KiB memory segment
                    while (lowAddress < 0x10000 && recordSize) {
                        recordSize = Math.min(
                            lineSize,                            // Normal case
                            blockEnd - highAddress - lowAddress, // End of block
                            0x10000 - lowAddress                 // End of low addresses
                        );

                        if (recordSize) {

                            recordHeader[0] = recordSize;   // Length
                            recordHeader[1] = lowAddress >> 8;    // Load offset, high byte
                            recordHeader[2] = lowAddress;    // Load offset, low byte
                            recordHeader[3] = 0;    // Record type

                            const subBlock = block.subarray(blockOffset, blockOffset + recordSize);   // Data bytes for this record

                            records.push(
                                ':' +
                                Array.prototype.map.call(recordHeader, hexpad).join('') +
                                Array.prototype.map.call(subBlock, hexpad).join('') +
                                hexpad(checksumTwo(recordHeader, subBlock))
                            );

                            blockOffset += recordSize;
                            lowAddress += recordSize;
                        }
                    }
                }
            }

            records.push(':00000001FF');    // EOF record

            return records.join('\n');
        }


        /**
         * Performs a deep copy of the current {@linkcode MemoryMap}, returning a new one
         * with exactly the same contents, but allocating new memory for each of its
         * <tt>Uint8Array</tt>s.
         *
         * @return {MemoryMap}
         */
        clone() {
            const cloned = new MemoryMap();

            for (let [addr, value] of this) {
                cloned.set(addr, new Uint8Array(value));
            }

            return cloned;
        }


        /**
         * Given one <tt>Uint8Array</tt>, looks through its contents and returns a new
         * {@linkcode MemoryMap}, stripping away those regions where there are only
         * padding bytes.
         * <br/>
         * The start of the input <tt>Uint8Array</tt> is assumed to be offset zero for the output.
         * <br/>
         * The use case here is dumping memory from a working device and try to see the
         * "interesting" memory regions it has. This assumes that there is a constant,
         * predefined padding byte value being used in the "non-interesting" regions.
         * In other words: this will work as long as the dump comes from a flash memory
         * which has been previously erased (thus <tt>0xFF</tt>s for padding), or from a
         * previously blanked HDD (thus <tt>0x00</tt>s for padding).
         * <br/>
         * This method uses <tt>subarray</tt> on the input data, and thus does not allocate memory
         * for the <tt>Uint8Array</tt>s.
         *
         * @param {Uint8Array} bytes The input data
         * @param {Number} [padByte=0xFF] The value of the byte assumed to be used as padding
         * @param {Number} [minPadLength=64] The minimum number of consecutive pad bytes to
         * be considered actual padding
         *
         * @return {MemoryMap}
         */
        static fromPaddedUint8Array(bytes, padByte=0xFF, minPadLength=64) {

            if (!(bytes instanceof Uint8Array)) {
                throw new Error('Bytes passed to fromPaddedUint8Array are not an Uint8Array');
            }

            // The algorithm used is naïve and checks every byte.
            // An obvious optimization would be to implement Boyer-Moore
            // (see https://en.wikipedia.org/wiki/Boyer%E2%80%93Moore_string_search_algorithm )
            // or otherwise start skipping up to minPadLength bytes when going through a non-pad
            // byte.
            // Anyway, we could expect a lot of cases where there is a majority of pad bytes,
            // and the algorithm should check most of them anyway, so the perf gain is questionable.

            const memMap = new MemoryMap();
            let consecutivePads = 0;
            let lastNonPad = -1;
            let firstNonPad = 0;
            let skippingBytes = false;
            const l = bytes.length;

            for (let addr = 0; addr < l; addr++) {
                const byte = bytes[addr];

                if (byte === padByte) {
                    consecutivePads++;
                    if (consecutivePads >= minPadLength) {
                        // Edge case: ignore writing a zero-length block when skipping
                        // bytes at the beginning of the input
                        if (lastNonPad !== -1) {
                            /// Add the previous block to the result memMap
                            memMap.set(firstNonPad, bytes.subarray(firstNonPad, lastNonPad+1));
                        }

                        skippingBytes = true;
                    }
                } else {
                    if (skippingBytes) {
                        skippingBytes = false;
                        firstNonPad = addr;
                    }
                    lastNonPad = addr;
                    consecutivePads = 0;
                }
            }

            // At EOF, add the last block if not skipping bytes already (and input not empty)
            if (!skippingBytes && lastNonPad !== -1) {
                memMap.set(firstNonPad, bytes.subarray(firstNonPad, l));
            }

            return memMap;
        }


        /**
         * Returns a new instance of {@linkcode MemoryMap}, containing only data between
         * the addresses <tt>address</tt> and <tt>address + length</tt>.
         * Behaviour is similar to {@linkcode https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Array/slice|Array.prototype.slice},
         * in that the return value is a portion of the current {@linkcode MemoryMap}.
         *
         * <br/>
         * The returned {@linkcode MemoryMap} might be empty.
         *
         * <br/>
         * Internally, this uses <tt>subarray</tt>, so new memory is not allocated.
         *
         * @param {Number} address The start address of the slice
         * @param {Number} length The length of memory map to slice out
         * @return {MemoryMap}
         */
        slice(address, length = Infinity){
            if (length < 0) {
                throw new Error('Length of the slice cannot be negative');
            }

            const sliced = new MemoryMap();

            for (let [blockAddr, block] of this) {
                const blockLength = block.length;

                if ((blockAddr + blockLength) >= address && blockAddr < (address + length)) {
                    const sliceStart = Math.max(address, blockAddr);
                    const sliceEnd = Math.min(address + length, blockAddr + blockLength);
                    const sliceLength = sliceEnd - sliceStart;
                    const relativeSliceStart = sliceStart - blockAddr;

                    if (sliceLength > 0) {
                        sliced.set(sliceStart, block.subarray(relativeSliceStart, relativeSliceStart + sliceLength));
                    }
                }
            }
            return sliced;
        }

        /**
         * Returns a new instance of {@linkcode https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/DataView/getUint32|Uint8Array}, containing only data between
         * the addresses <tt>address</tt> and <tt>address + length</tt>. Any byte without a value
         * in the input {@linkcode MemoryMap} will have a value of <tt>padByte</tt>.
         *
         * <br/>
         * This method allocates new memory.
         *
         * @param {Number} address The start address of the slice
         * @param {Number} length The length of memory map to slice out
         * @param {Number} [padByte=0xFF] The value of the byte assumed to be used as padding
         * @return {Uint8Array}
         */
        slicePad(address, length, padByte=0xFF){
            if (length < 0) {
                throw new Error('Length of the slice cannot be negative');
            }
            
            const out = (new Uint8Array(length)).fill(padByte);

            for (let [blockAddr, block] of this) {
                const blockLength = block.length;

                if ((blockAddr + blockLength) >= address && blockAddr < (address + length)) {
                    const sliceStart = Math.max(address, blockAddr);
                    const sliceEnd = Math.min(address + length, blockAddr + blockLength);
                    const sliceLength = sliceEnd - sliceStart;
                    const relativeSliceStart = sliceStart - blockAddr;

                    if (sliceLength > 0) {
                        out.set(block.subarray(relativeSliceStart, relativeSliceStart + sliceLength), sliceStart - address);
                    }
                }
            }
            return out;
        }

        /**
         * Checks whether the current memory map contains the one given as a parameter.
         *
         * <br/>
         * "Contains" means that all the offsets that have a byte value in the given
         * memory map have a value in the current memory map, and that the byte values
         * are the same.
         *
         * <br/>
         * An empty memory map is always contained in any other memory map.
         *
         * <br/>
         * Returns boolean <tt>true</tt> if the memory map is contained, <tt>false</tt>
         * otherwise.
         *
         * @param {MemoryMap} memMap The memory map to check
         * @return {Boolean}
         */
        contains(memMap) {
            for (let [blockAddr, block] of memMap) {

                const blockLength = block.length;

                const slice = this.slice(blockAddr, blockLength).join().get(blockAddr);

                if ((!slice) || slice.length !== blockLength ) {
                    return false;
                }

                for (const i in block) {
                    if (block[i] !== slice[i]) {
                        return false;
                    }
                }
            }
            return true;
        }
    }

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

    /**
     * Module to add and remove Python scripts into and from a MicroPython hex.
     *
     * (c) 2019 Micro:bit Educational Foundation and the microbit-fs contributors.
     * SPDX-License-Identifier: MIT
     */
    /** User script located at specific flash address. */
    var AppendedBlock;
    (function (AppendedBlock) {
        AppendedBlock[AppendedBlock["StartAdd"] = 253952] = "StartAdd";
        AppendedBlock[AppendedBlock["Length"] = 8192] = "Length";
        AppendedBlock[AppendedBlock["EndAdd"] = 262144] = "EndAdd";
    })(AppendedBlock || (AppendedBlock = {}));
    /** User code header */
    var AppendedHeader;
    (function (AppendedHeader) {
        AppendedHeader[AppendedHeader["Byte0"] = 0] = "Byte0";
        AppendedHeader[AppendedHeader["Byte1"] = 1] = "Byte1";
        AppendedHeader[AppendedHeader["CodeLengthLsb"] = 2] = "CodeLengthLsb";
        AppendedHeader[AppendedHeader["CodeLengthMsb"] = 3] = "CodeLengthMsb";
        AppendedHeader[AppendedHeader["Length"] = 4] = "Length";
    })(AppendedHeader || (AppendedHeader = {}));
    /** Start of user script marked by "MP" + 2 bytes for the script length. */
    const HEADER_START_BYTE_0 = 77; // 'M'
    const HEADER_START_BYTE_1 = 80; // 'P'
    /**
     * Marker placed inside the MicroPython hex string to indicate where to
     * inject the user Python Code.
     */
    const HEX_INSERTION_POINT = ':::::::::::::::::::::::::::::::::::::::::::\n';
    /**
     * Removes the old insertion line the input Intel Hex string contains it.
     *
     * @param intelHex - String with the intel hex lines.
     * @returns The Intel Hex string without insertion line.
     */
    function cleanseOldHexFormat(intelHex) {
        return intelHex.replace(HEX_INSERTION_POINT, '');
    }
    /**
     * Checks the Intel Hex memory map to see if there is an appended script.
     *
     * @param intelHexMap - Memory map for the MicroPython Intel Hex.
     * @returns True if appended script is present, false otherwise.
     */
    function isAppendedScriptPresent(intelHex) {
        let intelHexMap;
        if (typeof intelHex === 'string') {
            const intelHexClean = cleanseOldHexFormat(intelHex);
            intelHexMap = MemoryMap.fromHex(intelHexClean);
        }
        else {
            intelHexMap = intelHex;
        }
        const headerMagic = intelHexMap.slicePad(AppendedBlock.StartAdd, 2, 0xff);
        return (headerMagic[0] === HEADER_START_BYTE_0 &&
            headerMagic[1] === HEADER_START_BYTE_1);
    }

    /**
     * General utilities.
     * @packageDocumentation
     *
     * (c) 2020 Micro:bit Educational Foundation and the project contributors.
     * SPDX-License-Identifier: MIT
     */
    /**
     * Convert from a string with a hexadecimal number into a Uint8Array byte array.
     *
     * @export
     * @param hexStr A string with a hexadecimal number.
     * @returns A Uint8Array with the number broken down in bytes.
     */
    function hexStrToBytes(hexStr) {
        if (hexStr.length % 2 !== 0) {
            throw new Error("Hex string \"" + hexStr + "\" is not divisible by 2.");
        }
        var byteArray = hexStr.match(/.{1,2}/g);
        if (byteArray) {
            return new Uint8Array(byteArray.map(function (byteStr) {
                var byteNum = parseInt(byteStr, 16);
                if (Number.isNaN(byteNum)) {
                    throw new Error("There were some non-hex characters in \"" + hexStr + "\".");
                }
                else {
                    return byteNum;
                }
            }));
        }
        else {
            return new Uint8Array();
        }
    }
    /**
     * A version of byteToHexStr() without input sanitation, only to be called when
     * the caller can guarantee the input is a positive integer between 0 and 0xFF.
     *
     * @export
     * @param byte Number to convert into a hex string.
     * @returns String with hex value, padded to always have 2 characters.
     */
    function byteToHexStrFast(byte) {
        return byte.toString(16).toUpperCase().padStart(2, '0');
    }
    /**
     * Converts a Uint8Array into a string with base 16 hex digits. It doesn't
     * include an opening '0x'.
     *
     * @export
     * @param byteArray Uint8Array to convert to hex.
     * @returns String with base 16 hex digits.
     */
    function byteArrayToHexStr(byteArray) {
        return byteArray.reduce(function (accumulator, current) {
            return accumulator + current.toString(16).toUpperCase().padStart(2, '0');
        }, '');
    }
    /**
     * Concatenates an array of Uint8Arrays into a single Uint8Array.
     *
     * @export
     * @param arraysToConcat Arrays to concatenate.
     * @returns Single concatenated Uint8Array.
     */
    function concatUint8Arrays(arraysToConcat) {
        var fullLength = arraysToConcat.reduce(function (accumulator, currentValue) { return accumulator + currentValue.length; }, 0);
        var combined = new Uint8Array(fullLength);
        arraysToConcat.reduce(function (accumulator, currentArray) {
            combined.set(currentArray, accumulator);
            return accumulator + currentArray.length;
        }, 0);
        return combined;
    }

    /**
     * Generate and process Intel Hex records.
     * @packageDocumentation
     *
     * (c) 2020 Micro:bit Educational Foundation and contributors.
     * SPDX-License-Identifier: MIT
     */
    /** Values for the Record Type field, including Universal Hex custom types. */
    var RecordType;
    (function (RecordType) {
        RecordType[RecordType["Data"] = 0] = "Data";
        RecordType[RecordType["EndOfFile"] = 1] = "EndOfFile";
        RecordType[RecordType["ExtendedSegmentAddress"] = 2] = "ExtendedSegmentAddress";
        RecordType[RecordType["StartSegmentAddress"] = 3] = "StartSegmentAddress";
        RecordType[RecordType["ExtendedLinearAddress"] = 4] = "ExtendedLinearAddress";
        RecordType[RecordType["StartLinearAddress"] = 5] = "StartLinearAddress";
        RecordType[RecordType["BlockStart"] = 10] = "BlockStart";
        RecordType[RecordType["BlockEnd"] = 11] = "BlockEnd";
        RecordType[RecordType["PaddedData"] = 12] = "PaddedData";
        RecordType[RecordType["CustomData"] = 13] = "CustomData";
        RecordType[RecordType["OtherData"] = 14] = "OtherData";
    })(RecordType || (RecordType = {}));
    /**
     * The maximum data bytes per record is 0xFF, 16 and 32 bytes are the two most
     * common lengths, but DAPLink doesn't support more than 32 bytes.
     */
    var RECORD_DATA_MAX_BYTES = 32;
    /**
     * Constants for the record character lengths.
     */
    var START_CODE_STR = ':';
    var START_CODE_INDEX = 0;
    var START_CODE_STR_LEN = START_CODE_STR.length;
    var BYTE_COUNT_STR_INDEX = START_CODE_INDEX + START_CODE_STR_LEN;
    var BYTE_COUNT_STR_LEN = 2;
    var ADDRESS_STR_INDEX = BYTE_COUNT_STR_INDEX + BYTE_COUNT_STR_LEN;
    var ADDRESS_STR_LEN = 4;
    var RECORD_TYPE_STR_INDEX = ADDRESS_STR_INDEX + ADDRESS_STR_LEN;
    var RECORD_TYPE_STR_LEN = 2;
    var DATA_STR_INDEX = RECORD_TYPE_STR_INDEX + RECORD_TYPE_STR_LEN;
    var DATA_STR_LEN_MIN = 0;
    var CHECKSUM_STR_LEN = 2;
    var MIN_RECORD_STR_LEN = START_CODE_STR_LEN +
        BYTE_COUNT_STR_LEN +
        ADDRESS_STR_LEN +
        RECORD_TYPE_STR_LEN +
        DATA_STR_LEN_MIN +
        CHECKSUM_STR_LEN;
    var MAX_RECORD_STR_LEN = MIN_RECORD_STR_LEN - DATA_STR_LEN_MIN + RECORD_DATA_MAX_BYTES * 2;
    /**
     * Checks if a given number is a valid Record type.
     *
     * @param recordType Number to check
     * @returns True if it's a valid Record type.
     */
    function isRecordTypeValid(recordType) {
        // Checking ranges is more efficient than object key comparison
        // This also allow us use a const enum (compilation replaces it by literals)
        if ((recordType >= RecordType.Data &&
            recordType <= RecordType.StartLinearAddress) ||
            (recordType >= RecordType.BlockStart && recordType <= RecordType.OtherData)) {
            return true;
        }
        return false;
    }
    /**
     * Calculates the Intel Hex checksum.
     *
     * This is basically the LSB of the two's complement of the sum of all bytes.
     *
     * @param dataBytes A byte array to calculate the checksum into.
     * @returns Checksum byte.
     */
    function calcChecksumByte(dataBytes) {
        var sum = dataBytes.reduce(function (accumulator, currentValue) { return accumulator + currentValue; }, 0);
        return -sum & 0xff;
    }
    /**
     * Creates an Intel Hex record with normal or custom record types.
     *
     * @param address - The two least significant bytes for the data address.
     * @param recordType - Record type, could be one of the standard types or any
     *    of the custom types created for forming a Universal Hex.
     * @param dataBytes - Byte array with the data to include in the record.
     * @returns A string with the Intel Hex record.
     */
    function createRecord(address, recordType, dataBytes) {
        var byteCount = dataBytes.length;
        if (byteCount > RECORD_DATA_MAX_BYTES) {
            throw new Error("Record (" + recordType + ") data has too many bytes (" + byteCount + ").");
        }
        if (!isRecordTypeValid(recordType)) {
            throw new Error("Record type '" + recordType + "' is not valid.");
        }
        var recordContent = concatUint8Arrays([
            new Uint8Array([byteCount, address >> 8, address & 0xff, recordType]),
            dataBytes,
        ]);
        var recordContentStr = byteArrayToHexStr(recordContent);
        var checksumStr = byteToHexStrFast(calcChecksumByte(recordContent));
        return "" + START_CODE_STR + recordContentStr + checksumStr;
    }
    /**
     * Check if an Intel Hex record conforms to the following rules:
     *  - Correct length of characters
     *  - Starts with a colon
     *
     * TODO: Apply more rules.
     *
     * @param iHexRecord - Single Intel Hex record to check.
     * @returns A boolean indicating if the record is valid.
     */
    function validateRecord(iHexRecord) {
        if (iHexRecord.length < MIN_RECORD_STR_LEN) {
            throw new Error("Record length too small: " + iHexRecord);
        }
        if (iHexRecord.length > MAX_RECORD_STR_LEN) {
            throw new Error("Record length is too large: " + iHexRecord);
        }
        if (iHexRecord[0] !== ':') {
            throw new Error("Record does not start with a \":\": " + iHexRecord);
        }
        return true;
    }
    /**
     * Retrieves the Record Type form an Intel Hex record line.
     *
     * @param iHexRecord Intel hex record line without line terminator.
     * @returns The RecordType value.
     */
    function getRecordType(iHexRecord) {
        validateRecord(iHexRecord);
        var recordTypeCharStart = START_CODE_STR_LEN + BYTE_COUNT_STR_LEN + ADDRESS_STR_LEN;
        var recordTypeStr = iHexRecord.slice(recordTypeCharStart, recordTypeCharStart + RECORD_TYPE_STR_LEN);
        var recordType = parseInt(recordTypeStr, 16);
        if (!isRecordTypeValid(recordType)) {
            throw new Error("Record type '" + recordTypeStr + "' from record '" + iHexRecord + "' is not valid.");
        }
        return recordType;
    }
    /**
     * Retrieves the data field from a record.
     *
     * @param iHexRecord Intel Hex record string.
     * @returns The record Data in a byte array.
     */
    function getRecordData(iHexRecord) {
        try {
            // The only thing after the Data bytes is the Checksum (2 characters)
            return hexStrToBytes(iHexRecord.slice(DATA_STR_INDEX, -2));
        }
        catch (e) {
            throw new Error("Could not parse Intel Hex record \"" + iHexRecord + "\": " + e.message);
        }
    }
    /**
     * Parses an Intel Hex record into an Record object with its respective fields.
     *
     * @param iHexRecord Intel hex record line without line terminator.
     * @returns New object with the Record interface.
     */
    function parseRecord(iHexRecord) {
        validateRecord(iHexRecord);
        var recordBytes;
        try {
            recordBytes = hexStrToBytes(iHexRecord.substring(1));
        }
        catch (e) {
            throw new Error("Could not parse Intel Hex record \"" + iHexRecord + "\": " + e.message);
        }
        var byteCountIndex = 0;
        var byteCount = recordBytes[0];
        var addressIndex = byteCountIndex + BYTE_COUNT_STR_LEN / 2;
        var address = (recordBytes[addressIndex] << 8) + recordBytes[addressIndex + 1];
        var recordTypeIndex = addressIndex + ADDRESS_STR_LEN / 2;
        var recordType = recordBytes[recordTypeIndex];
        var dataIndex = recordTypeIndex + RECORD_TYPE_STR_LEN / 2;
        var checksumIndex = dataIndex + byteCount;
        var data = recordBytes.slice(dataIndex, checksumIndex);
        var checksum = recordBytes[checksumIndex];
        var totalLength = checksumIndex + CHECKSUM_STR_LEN / 2;
        if (recordBytes.length > totalLength) {
            throw new Error("Parsed record \"" + iHexRecord + "\" is larger than indicated by the byte count." +
                ("\n\tExpected: " + totalLength + "; Length: " + recordBytes.length + "."));
        }
        return {
            byteCount: byteCount,
            address: address,
            recordType: recordType,
            data: data,
            checksum: checksum,
        };
    }
    /**
     * Creates an End Of File Intel Hex record.
     *
     * @returns End of File record with new line.
     */
    function endOfFileRecord() {
        // No need to use createRecord(), this record is always the same
        return ':00000001FF';
    }
    /**
     * Creates an Extended Linear Address record from a 4 byte address.
     *
     * @param address - Full 32 bit address.
     * @returns The Extended Linear Address Intel Hex record.
     */
    function extLinAddressRecord(address) {
        if (address < 0 || address > 0xffffffff) {
            throw new Error("Address '" + address + "' for Extended Linear Address record is out of range.");
        }
        return createRecord(0, RecordType.ExtendedLinearAddress, new Uint8Array([(address >> 24) & 0xff, (address >> 16) & 0xff]));
    }
    /**
     * Creates a Block Start (custom) Intel Hex Record.
     *
     * @param boardId Board ID to embed into the record, 0 to 0xFFF.
     * @returns A Block Start (custom) Intel Hex record.
     */
    function blockStartRecord(boardId) {
        if (boardId < 0 || boardId > 0xffff) {
            throw new Error('Board ID out of range when creating Block Start record.');
        }
        return createRecord(0, RecordType.BlockStart, new Uint8Array([(boardId >> 8) & 0xff, boardId & 0xff, 0xc0, 0xde]));
    }
    /**
     * Create Block End (custom) Intel Hex Record.
     *
     * The Data field in this Record will be ignored and can be used for padding.
     *
     * @param padBytesLen Number of bytes to add to the Data field.
     * @returns A Block End (custom) Intel Hex record.
     */
    function blockEndRecord(padBytesLen) {
        // This function is called very often with the same arguments, so cache
        // those results for better performance
        switch (padBytesLen) {
            case 0x4:
                // Common for blocks that have full Data records with 0x10 bytes and a
                // single Extended Linear Address record
                return ':0400000BFFFFFFFFF5';
            case 0x0c:
                // The most common padding, when a block has 10 full (0x10) Data records
                return ':0C00000BFFFFFFFFFFFFFFFFFFFFFFFFF5';
            default:
                // Input sanitation will be done in createRecord, no need to do it here too
                var recordData = new Uint8Array(padBytesLen).fill(0xff);
                return createRecord(0, RecordType.BlockEnd, recordData);
        }
    }
    /**
     * Create a Padded Data (custom) Intel Hex Record.
     * This record is used to add padding data, to be ignored by DAPLink, to be able
     * to create blocks of 512-bytes.
     *
     * @param padBytesLen Number of bytes to add to the Data field.
     * @returns A Padded Data (custom) Intel Hex record.
     */
    function paddedDataRecord(padBytesLen) {
        // Input sanitation will be done in createRecord, no need to do it here too
        var recordData = new Uint8Array(padBytesLen).fill(0xff);
        return createRecord(0, RecordType.PaddedData, recordData);
    }
    /**
     * Changes the record type of a Record to a Custom Data type.
     *
     * The data field is kept, but changing the record type will trigger the
     * checksum to be updated as well.
     *
     * @param iHexRecord Intel hex record line without line terminator.
     * @returns A Custom Data Intel Hex record with the same data field.
     */
    function convertRecordTo(iHexRecord, recordType) {
        var oRecord = parseRecord(iHexRecord);
        var recordContent = new Uint8Array(oRecord.data.length + 4);
        recordContent[0] = oRecord.data.length;
        recordContent[1] = oRecord.address >> 8;
        recordContent[2] = oRecord.address & 0xff;
        recordContent[3] = recordType;
        recordContent.set(oRecord.data, 4);
        var recordContentStr = byteArrayToHexStr(recordContent);
        var checksumStr = byteToHexStrFast(calcChecksumByte(recordContent));
        return "" + START_CODE_STR + recordContentStr + checksumStr;
    }
    /**
     * Converts and Extended Segment Linear Address record to an Extended Linear
     * Address record.
     *
     * @throws {Error} When the record does not contain exactly 2 bytes.
     * @throws {Error} When the Segmented Address is not a multiple of 0x1000.
     *
     * @param iHexRecord Intel hex record line without line terminator.
     */
    function convertExtSegToLinAddressRecord(iHexRecord) {
        var segmentAddress = getRecordData(iHexRecord);
        if (segmentAddress.length !== 2 ||
            segmentAddress[0] & 0xf || // Only process multiples of 0x1000
            segmentAddress[1] !== 0) {
            throw new Error("Invalid Extended Segment Address record " + iHexRecord);
        }
        var startAddress = segmentAddress[0] << 12;
        return extLinAddressRecord(startAddress);
    }
    /**
     * Separates an Intel Hex file (string) into an array of Record strings.
     *
     * @param iHexStr Intel Hex file as a string.
     * @returns Array of Records in string format.
     */
    function iHexToRecordStrs(iHexStr) {
        // For some reason this is quicker than .split(/\r?\n/)
        // Up to x200 faster in Chrome (!) and x1.5 faster in Firefox
        var output = iHexStr.replace(/\r/g, '').split('\n');
        // Boolean filter removes all falsy values as some of these files contain
        // multiple empty lines we want to remove
        return output.filter(Boolean);
    }
    /**
     * Iterates through the beginning of an array of Intel Hex records to find the
     * longest record data field length.
     *
     * Once it finds 12 records at the maximum size found so far (starts at 16
     * bytes) it will stop iterating.
     *
     * This is useful to identify the expected max size of the data records for an
     * Intel Hex, and then be able to generate new custom records of the same size.
     *
     * @param iHexRecords Array of Intel Hex Records.
     * @returns Number of data bytes in a full record.
     */
    function findDataFieldLength(iHexRecords) {
        var maxDataBytes = 16;
        var maxDataBytesCount = 0;
        for (var _i = 0, iHexRecords_1 = iHexRecords; _i < iHexRecords_1.length; _i++) {
            var record = iHexRecords_1[_i];
            var dataBytesLength = (record.length - MIN_RECORD_STR_LEN) / 2;
            if (dataBytesLength > maxDataBytes) {
                maxDataBytes = dataBytesLength;
                maxDataBytesCount = 0;
            }
            else if (dataBytesLength === maxDataBytes) {
                maxDataBytesCount++;
            }
            if (maxDataBytesCount > 12) {
                break;
            }
        }
        if (maxDataBytes > RECORD_DATA_MAX_BYTES) {
            throw new Error("Intel Hex record data size is too large: " + maxDataBytes);
        }
        return maxDataBytes;
    }

    /**
     * Convert between standard Intel Hex strings and Universal Hex strings.
     *
     * This module provides the main functionality to convert Intel Hex strings
     * (with their respective Board IDs) into the Universal Hex format.
     *
     * It can also separate a Universal Hex string into the individual Intel Hex
     * strings that forms it.
     *
     * The content here assumes familiarity with the
     * [Universal Hex Specification](https://github.com/microbit-foundation/spec-universal-hex)
     * and the rest of
     * [this library documentation](https://microbit-foundation.github.io/microbit-universal-hex/).
     * @packageDocumentation
     *
     * (c) 2020 Micro:bit Educational Foundation and the project contributors.
     * SPDX-License-Identifier: MIT
     */
    var V1_BOARD_IDS = [0x9900, 0x9901];
    var BLOCK_SIZE = 512;
    /**
     * The Board ID is used to identify the different targets from a Universal Hex.
     * In this case the target represents a micro:bit version.
     * For micro:bit V1 (v1.3, v1.3B and v1.5) the `boardId` is `0x9900`, and for
     * V2 `0x9903`.
     */
    var microbitBoardId$1;
    (function (microbitBoardId) {
        microbitBoardId[microbitBoardId["V1"] = 39168] = "V1";
        microbitBoardId[microbitBoardId["V2"] = 39171] = "V2";
    })(microbitBoardId$1 || (microbitBoardId$1 = {}));
    /**
     * Converts an Intel Hex string into a Hex string using the 512 byte blocks
     * format and the Universal Hex specific record types.
     *
     * The output of this function is not a fully formed Universal Hex, but one part
     * of a Universal Hex, ready to be merged by the calling code.
     *
     * More information on this "block" format:
     *   https://github.com/microbit-foundation/spec-universal-hex
     *
     * @throws {Error} When the Board ID is not between 0 and 2^16.
     * @throws {Error} When there is an EoF record not at the end of the file.
     *
     * @param iHexStr - Intel Hex string to convert into the custom format with 512
     *    byte blocks and the customer records.
     * @returns New Intel Hex string with the custom format.
     */
    function iHexToCustomFormatBlocks(iHexStr, boardId) {
        // Hex files for v1.3 and v1.5 continue using the normal Data Record Type
        var replaceDataRecord = !V1_BOARD_IDS.includes(boardId);
        // Generate some constant records
        var startRecord = blockStartRecord(boardId);
        var currentExtAddr = extLinAddressRecord(0);
        // Pre-calculate known record lengths
        var extAddrRecordLen = currentExtAddr.length;
        var startRecordLen = startRecord.length;
        var endRecordBaseLen = blockEndRecord(0).length;
        var padRecordBaseLen = paddedDataRecord(0).length;
        var hexRecords = iHexToRecordStrs(iHexStr);
        var recordPaddingCapacity = findDataFieldLength(hexRecords);
        if (!hexRecords.length)
            return '';
        if (isUniversalHexRecords(hexRecords)) {
            throw new Error("Board ID " + boardId + " Hex is already a Universal Hex.");
        }
        // Each loop iteration corresponds to a 512-bytes block
        var ih = 0;
        var blockLines = [];
        while (ih < hexRecords.length) {
            var blockLen = 0;
            // Check for an extended linear record to not repeat it after a block start
            var firstRecordType = getRecordType(hexRecords[ih]);
            if (firstRecordType === RecordType.ExtendedLinearAddress) {
                currentExtAddr = hexRecords[ih];
                ih++;
            }
            else if (firstRecordType === RecordType.ExtendedSegmentAddress) {
                currentExtAddr = convertExtSegToLinAddressRecord(hexRecords[ih]);
                ih++;
            }
            blockLines.push(currentExtAddr);
            blockLen += extAddrRecordLen + 1;
            blockLines.push(startRecord);
            blockLen += startRecordLen + 1;
            blockLen += endRecordBaseLen + 1;
            var endOfFile = false;
            while (hexRecords[ih] &&
                BLOCK_SIZE >= blockLen + hexRecords[ih].length + 1) {
                var record = hexRecords[ih++];
                var recordType = getRecordType(record);
                if (replaceDataRecord && recordType === RecordType.Data) {
                    record = convertRecordTo(record, RecordType.CustomData);
                }
                else if (recordType === RecordType.ExtendedLinearAddress) {
                    currentExtAddr = record;
                }
                else if (recordType === RecordType.ExtendedSegmentAddress) {
                    record = convertExtSegToLinAddressRecord(record);
                    currentExtAddr = record;
                }
                else if (recordType === RecordType.EndOfFile) {
                    endOfFile = true;
                    break;
                }
                blockLines.push(record);
                blockLen += record.length + 1;
            }
            if (endOfFile) {
                // Error if we encounter an EoF record and it's not the end of the file
                if (ih !== hexRecords.length) {
                    // Might be MakeCode hex for V1 as they did this with the EoF record
                    if (isMakeCodeForV1HexRecords(hexRecords)) {
                        throw new Error("Board ID " + boardId + " Hex is from MakeCode, import this hex into the MakeCode editor to create a Universal Hex.");
                    }
                    else {
                        throw new Error("EoF record found at record " + ih + " of " + hexRecords.length + " in Board ID " + boardId + " hex");
                    }
                }
                // The EoF record goes after the Block End Record, it won't break 512-byte
                // boundary as it was already calculated in the previous loop that it fits
                blockLines.push(blockEndRecord(0));
                blockLines.push(endOfFileRecord());
            }
            else {
                // We might need additional padding records
                // const charsLeft = BLOCK_SIZE - blockLen;
                while (BLOCK_SIZE - blockLen > recordPaddingCapacity * 2) {
                    var record = paddedDataRecord(Math.min((BLOCK_SIZE - blockLen - (padRecordBaseLen + 1)) / 2, recordPaddingCapacity));
                    blockLines.push(record);
                    blockLen += record.length + 1;
                }
                blockLines.push(blockEndRecord((BLOCK_SIZE - blockLen) / 2));
            }
        }
        blockLines.push(''); // Ensure there is a blank new line at the end
        return blockLines.join('\n');
    }
    /**
     * Converts an Intel Hex string into a Hex string using custom records and
     * aligning the content size to a 512-byte boundary.
     *
     * The output of this function is not a fully formed Universal Hex, but one part
     * of a Universal Hex, ready to be merged by the calling code.
     *
     * More information on this "section" format:
     *   https://github.com/microbit-foundation/spec-universal-hex
     *
     * @throws {Error} When the Board ID is not between 0 and 2^16.
     * @throws {Error} When there is an EoF record not at the end of the file.
     *
     * @param iHexStr - Intel Hex string to convert into the custom format with 512
     *    byte blocks and the customer records.
     * @returns New Intel Hex string with the custom format.
     */
    function iHexToCustomFormatSection(iHexStr, boardId) {
        var sectionLines = [];
        var sectionLen = 0;
        var ih = 0;
        var addRecordLength = function (record) {
            sectionLen += record.length + 1; // Extra character counted for '\n'
        };
        var addRecord = function (record) {
            sectionLines.push(record);
            addRecordLength(record);
        };
        var hexRecords = iHexToRecordStrs(iHexStr);
        if (!hexRecords.length)
            return '';
        if (isUniversalHexRecords(hexRecords)) {
            throw new Error("Board ID " + boardId + " Hex is already a Universal Hex.");
        }
        // If first record is not an Extended Segmented/Linear Address we start at 0x0
        var iHexFirstRecordType = getRecordType(hexRecords[0]);
        if (iHexFirstRecordType === RecordType.ExtendedLinearAddress) {
            addRecord(hexRecords[0]);
            ih++;
        }
        else if (iHexFirstRecordType === RecordType.ExtendedSegmentAddress) {
            addRecord(convertExtSegToLinAddressRecord(hexRecords[0]));
            ih++;
        }
        else {
            addRecord(extLinAddressRecord(0));
        }
        // Add the Block Start record to the beginning of the segment
        addRecord(blockStartRecord(boardId));
        // Iterate through the rest of the records and add them
        var replaceDataRecord = !V1_BOARD_IDS.includes(boardId);
        var endOfFile = false;
        while (ih < hexRecords.length) {
            var record = hexRecords[ih++];
            var recordType = getRecordType(record);
            if (recordType === RecordType.Data) {
                addRecord(replaceDataRecord
                    ? convertRecordTo(record, RecordType.CustomData)
                    : record);
            }
            else if (recordType === RecordType.ExtendedSegmentAddress) {
                addRecord(convertExtSegToLinAddressRecord(record));
            }
            else if (recordType === RecordType.ExtendedLinearAddress) {
                addRecord(record);
            }
            else if (recordType === RecordType.EndOfFile) {
                endOfFile = true;
                break;
            }
        }
        if (ih !== hexRecords.length) {
            // The End Of File record was encountered mid-file, might be a MakeCode hex
            if (isMakeCodeForV1HexRecords(hexRecords)) {
                throw new Error("Board ID " + boardId + " Hex is from MakeCode, import this hex into the MakeCode editor to create a Universal Hex.");
            }
            else {
                throw new Error("EoF record found at record " + ih + " of " + hexRecords.length + " in Board ID " + boardId + " hex ");
            }
        }
        // Add to the section size calculation the minimum length for the Block End
        // record that will be placed at the end (no padding included yet)
        addRecordLength(blockEndRecord(0));
        // Calculate padding required to end in a 512-byte boundary
        var recordNoDataLenChars = paddedDataRecord(0).length + 1;
        var recordDataMaxBytes = findDataFieldLength(hexRecords);
        var paddingCapacityChars = recordDataMaxBytes * 2;
        var charsNeeded = (BLOCK_SIZE - (sectionLen % BLOCK_SIZE)) % BLOCK_SIZE;
        while (charsNeeded > paddingCapacityChars) {
            var byteLen = (charsNeeded - recordNoDataLenChars) >> 1; // Integer div 2
            var record = paddedDataRecord(Math.min(byteLen, recordDataMaxBytes));
            addRecord(record);
            charsNeeded = (BLOCK_SIZE - (sectionLen % BLOCK_SIZE)) % BLOCK_SIZE;
        }
        sectionLines.push(blockEndRecord(charsNeeded >> 1));
        if (endOfFile)
            sectionLines.push(endOfFileRecord());
        sectionLines.push(''); // Ensure there is a blank new line at the end
        return sectionLines.join('\n');
    }
    /**
     * Creates a Universal Hex from a collection of Intel Hex strings and their
     * board IDs.
     *
     * For the current micro:bit board versions use the values from the
     * `microbitBoardId` enum.
     *
     * @param hexes An array of objects containing an Intel Hex string and the board
     *     ID associated with it.
     * @param blocks Indicate if the Universal Hex format should be "blocks"
     *     instead of "sections". The current specification recommends using the
     *     default "sections" format as is much quicker in micro:bits with DAPLink
     *     version 0234.
     * @returns A Universal Hex string.
     */
    function createUniversalHex(hexes, blocks) {
        if (blocks === void 0) { blocks = false; }
        if (!hexes.length)
            return '';
        var iHexToCustomFormat = blocks
            ? iHexToCustomFormatBlocks
            : iHexToCustomFormatSection;
        var eofNlRecord = endOfFileRecord() + '\n';
        var customHexes = [];
        // We remove the EoF record from all but the last hex file so that the last
        // blocks are padded and there is single EoF record
        for (var i = 0; i < hexes.length - 1; i++) {
            var customHex = iHexToCustomFormat(hexes[i].hex, hexes[i].boardId);
            if (customHex.endsWith(eofNlRecord)) {
                customHex = customHex.slice(0, customHex.length - eofNlRecord.length);
            }
            customHexes.push(customHex);
        }
        // Process the last hex file with a guaranteed EoF record
        var lastCustomHex = iHexToCustomFormat(hexes[hexes.length - 1].hex, hexes[hexes.length - 1].boardId);
        customHexes.push(lastCustomHex);
        if (!lastCustomHex.endsWith(eofNlRecord)) {
            customHexes.push(eofNlRecord);
        }
        return customHexes.join('');
    }
    /**
     * Checks if the provided hex string is a Universal Hex.
     *
     * Very simple test only checking for the opening Extended Linear Address and
     * Block Start records.
     *
     * The string is manually iterated as this method can be x20 faster than
     * breaking the string into records and checking their types with the ihex
     * functions.
     *
     * @param hexStr Hex string to check
     * @return True if the hex is an Universal Hex.
     */
    function isUniversalHex(hexStr) {
        // Check the beginning of the Extended Linear Address record
        var elaRecordBeginning = ':02000004';
        if (hexStr.slice(0, elaRecordBeginning.length) !== elaRecordBeginning) {
            return false;
        }
        // Find the index for the next record, as we have unknown line endings
        var i = elaRecordBeginning.length;
        while (hexStr[++i] !== ':' && i < MAX_RECORD_STR_LEN + 3)
            ;
        // Check the beginning of the Block Start record
        var blockStartBeginning = ':0400000A';
        if (hexStr.slice(i, i + blockStartBeginning.length) !== blockStartBeginning) {
            return false;
        }
        return true;
    }
    /**
     * Checks if the provided array of hex records form part of a Universal Hex.
     *
     * @param records Array of hex records to check.
     * @return True if the records belong to a Universal Hex.
     */
    function isUniversalHexRecords(records) {
        return (getRecordType(records[0]) === RecordType.ExtendedLinearAddress &&
            getRecordType(records[1]) === RecordType.BlockStart &&
            getRecordType(records[records.length - 1]) ===
                RecordType.EndOfFile);
    }
    /**
     * Checks if the array of records belongs to an Intel Hex file from MakeCode for
     * micro:bit V1.
     *
     * @param records Array of hex records to check.
     * @return True if the records belong to a MakeCode hex file for micro:bit V1.
     */
    function isMakeCodeForV1HexRecords(records) {
        var i = records.indexOf(endOfFileRecord());
        if (i === records.length - 1) {
            // A MakeCode v0 hex file will place the metadata in RAM before the EoF
            while (--i > 0) {
                if (records[i] === extLinAddressRecord(0x20000000)) {
                    return true;
                }
            }
        }
        while (++i < records.length) {
            // Other data records used to store the MakeCode project metadata (v2 and v3)
            if (getRecordType(records[i]) === RecordType.OtherData) {
                return true;
            }
            // In MakeCode v1 metadata went to RAM memory space 0x2000_0000
            if (records[i] === extLinAddressRecord(0x20000000)) {
                return true;
            }
        }
        return false;
    }
    /**
     * Separates a Universal Hex into its individual Intel Hexes.
     *
     * @param universalHexStr Universal Hex string with the Universal Hex.
     * @returns An array of object with boardId and hex keys.
     */
    function separateUniversalHex(universalHexStr) {
        var records = iHexToRecordStrs(universalHexStr);
        if (!records.length)
            throw new Error('Empty Universal Hex.');
        if (!isUniversalHexRecords(records)) {
            throw new Error('Universal Hex format invalid.');
        }
        var passThroughRecords = [
            RecordType.Data,
            RecordType.EndOfFile,
            RecordType.ExtendedSegmentAddress,
            RecordType.StartSegmentAddress,
        ];
        // Initialise the structure to hold the different hexes
        var hexes = {};
        var currentBoardId = 0;
        for (var i = 0; i < records.length; i++) {
            var record = records[i];
            var recordType = getRecordType(record);
            if (passThroughRecords.includes(recordType)) {
                hexes[currentBoardId].hex.push(record);
            }
            else if (recordType === RecordType.CustomData) {
                hexes[currentBoardId].hex.push(convertRecordTo(record, RecordType.Data));
            }
            else if (recordType === RecordType.ExtendedLinearAddress) {
                // Extended Linear Address can be found as the start of a new block
                // No need to check array size as it's confirmed hex ends with an EoF
                var nextRecord = records[i + 1];
                if (getRecordType(nextRecord) === RecordType.BlockStart) {
                    // Processes the Block Start record (only first 2 bytes for Board ID)
                    var blockStartData = getRecordData(nextRecord);
                    if (blockStartData.length !== 4) {
                        throw new Error("Block Start record invalid: " + nextRecord);
                    }
                    currentBoardId = (blockStartData[0] << 8) + blockStartData[1];
                    hexes[currentBoardId] = hexes[currentBoardId] || {
                        boardId: currentBoardId,
                        lastExtAdd: record,
                        hex: [record],
                    };
                    i++;
                }
                if (hexes[currentBoardId].lastExtAdd !== record) {
                    hexes[currentBoardId].lastExtAdd = record;
                    hexes[currentBoardId].hex.push(record);
                }
            }
        }
        // Form the return object with the same format as createUniversalHex() input
        var returnArray = [];
        Object.keys(hexes).forEach(function (boardId) {
            // Ensure all hexes (and not just the last) contain the EoF record
            var hex = hexes[boardId].hex;
            if (hex[hex.length - 1] !== endOfFileRecord()) {
                hex[hex.length] = endOfFileRecord();
            }
            returnArray.push({
                boardId: hexes[boardId].boardId,
                hex: hex.join('\n') + '\n',
            });
        });
        return returnArray;
    }

    /**
     * Utilities for retrieving data from MemoryMap instances from the nrf-intel-hex
     * library.
     */
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
    function getUint64(intelHexMap, address) {
        const uint64Data = intelHexMap.slicePad(address, 8, 0xff);
        // Typed arrays use the native endianness, force little endian with DataView
        return new DataView(uint64Data.buffer).getUint32(0, true /* little endian */);
    }
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
    function getUint32(intelHexMap, address) {
        const uint32Data = intelHexMap.slicePad(address, 4, 0xff);
        // Typed arrays use the native endianness, force little endian with DataView
        return new DataView(uint32Data.buffer).getUint32(0, true /* little endian */);
    }
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
    function getUint16(intelHexMap, address) {
        const uint16Data = intelHexMap.slicePad(address, 2, 0xff);
        // Typed arrays use the native endianness, force little endian with DataView
        return new DataView(uint16Data.buffer).getUint16(0, true /* little endian */);
    }
    /**
     * Reads a 8 bit number from an Intel Hex memory map.
     *
     * If the data is not contained inside the MemoryMap it returns 0xFF.
     *
     * @param intelHexMap - Memory map of the Intel Hex data.
     * @param address - Start address of the 16 bit number.
     * @returns Number with the unsigned integer representation of those 2 bytes.
     */
    function getUint8(intelHexMap, address) {
        const uint16Data = intelHexMap.slicePad(address, 1, 0xff);
        return uint16Data[0];
    }
    /**
     * Decodes a UTF-8 null terminated string stored in the Intel Hex data at
     * the indicated address.
     *
     * @param intelHexMap - Memory map of the Intel Hex data.
     * @param address - Start address for the string.
     * @returns String read from the Intel Hex data.
     */
    function getString(intelHexMap, address) {
        const memBlock = intelHexMap.slice(address).get(address);
        let iStrEnd = 0;
        while (iStrEnd < memBlock.length && memBlock[iStrEnd] !== 0)
            iStrEnd++;
        if (iStrEnd === memBlock.length) {
            // Could not find a null character to indicate the end of the string
            return '';
        }
        const stringBytes = memBlock.slice(0, iStrEnd);
        return bytesToStr(stringBytes);
    }

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
    /** Indicates the data contain in each of the different regions */
    var RegionId;
    (function (RegionId) {
        /** Soft Device is the data blob containing the Nordic Bluetooth stack. */
        RegionId[RegionId["softDevice"] = 1] = "softDevice";
        /** Contains the MicroPython runtime. */
        RegionId[RegionId["microPython"] = 2] = "microPython";
        /** Contains the MicroPython microbit filesystem reserved flash. */
        RegionId[RegionId["fs"] = 3] = "fs";
    })(RegionId || (RegionId = {}));
    /**
     * The "hash type" field in a region row indicates how to interpret the "hash
     * data" field.
     */
    var RegionHashType;
    (function (RegionHashType) {
        /** The hash data is empty. */
        RegionHashType[RegionHashType["empty"] = 0] = "empty";
        /** The full hash data field is used as a hash of the region in flash */
        RegionHashType[RegionHashType["data"] = 1] = "data";
        /** The 4 LSB bytes of the hash data field are used as a pointer  */
        RegionHashType[RegionHashType["pointer"] = 2] = "pointer";
    })(RegionHashType || (RegionHashType = {}));
    const MAGIC_1_LEN_BYTES = 4;
    /**
     * Offset for each of the Table header fields, starting from the end of the row.
     *
     * These are the fields stored in each row for each of the regions, and
     * any additional region data from the Region interface is derived from this.
     *
     * |0x00|..|..|0x03|0x04|0x05|0x06|0x07|0x08|0x09|0x0a|0x0b|0x0c|..|..|0x0f|
     * |----|--|--|----|----|----|----|----|----|----|----|----|----|--|--|----|
     * | MAGIC_1       | VERSION |TABLE_LEN|REG_COUNT| P_SIZE  | MAGIC_2       |
     */
    var RegionHeaderOffset;
    (function (RegionHeaderOffset) {
        RegionHeaderOffset[RegionHeaderOffset["magic2"] = 4] = "magic2";
        RegionHeaderOffset[RegionHeaderOffset["pageSizeLog2"] = 6] = "pageSizeLog2";
        RegionHeaderOffset[RegionHeaderOffset["regionCount"] = 8] = "regionCount";
        RegionHeaderOffset[RegionHeaderOffset["tableLength"] = 10] = "tableLength";
        RegionHeaderOffset[RegionHeaderOffset["version"] = 12] = "version";
        RegionHeaderOffset[RegionHeaderOffset["magic1"] = 16] = "magic1";
    })(RegionHeaderOffset || (RegionHeaderOffset = {}));
    // Magic numbers to identify the Flash Regions Table in flash
    const REGION_HEADER_MAGIC_1 = 0x597f30fe;
    const REGION_HEADER_MAGIC_2 = 0xc1b1d79d;
    /**
     * Offset for each of the Region row fields, starting from the end of the row.
     *
     * These are the fields stored in each row for each of the regions, and
     * any additional region data from the Region interface is derived from this.
     *
     * |0x00|0x01|0x02|0x03|0x04|0x05|0x06|0x07|0x08|..|..|..|..|..|..|0x0f|
     * |----|----|----|----|----|----|----|----|----|--|--|--|--|--|--|----|
     * | ID | HT |1ST_PAGE | REGION_LENGTH     | HASH_DATA                 |
     */
    var RegionRowOffset;
    (function (RegionRowOffset) {
        RegionRowOffset[RegionRowOffset["hashData"] = 8] = "hashData";
        RegionRowOffset[RegionRowOffset["lengthBytes"] = 12] = "lengthBytes";
        RegionRowOffset[RegionRowOffset["startPage"] = 14] = "startPage";
        RegionRowOffset[RegionRowOffset["hashType"] = 15] = "hashType";
        RegionRowOffset[RegionRowOffset["id"] = 16] = "id";
    })(RegionRowOffset || (RegionRowOffset = {}));
    const REGION_ROW_LEN_BYTES = RegionRowOffset.id;
    /**
     * Iterates through the provided Intel Hex Memory Map and tries to find the
     * Flash Regions Table header, by looking for the magic values at the end of
     * each flash page.
     *
     * TODO: Indicate here what errors can be thrown.
     *
     * @param iHexMap - Intel Hex memory map to scan for the Flash Regions Table.
     * @param pSize - Flash page size to scan at the end of each page.
     * @returns The table header data.
     */
    function getTableHeader(iHexMap, pSize = 1024) {
        let endAddress = 0;
        const magic1ToFind = new Uint8Array(new Uint32Array([REGION_HEADER_MAGIC_1]).buffer);
        const magic2ToFind = new Uint8Array(new Uint32Array([REGION_HEADER_MAGIC_2]).buffer);
        const mapEntries = iHexMap.paginate(pSize, 0xff).entries();
        for (let iter = mapEntries.next(); !iter.done; iter = mapEntries.next()) {
            if (!iter.value)
                continue;
            const blockByteArray = iter.value[1];
            const subArrayMagic2 = blockByteArray.subarray(-RegionHeaderOffset.magic2);
            if (areUint8ArraysEqual(subArrayMagic2, magic2ToFind) &&
                areUint8ArraysEqual(blockByteArray.subarray(-RegionHeaderOffset.magic1, -(RegionHeaderOffset.magic1 - MAGIC_1_LEN_BYTES)), magic1ToFind)) {
                const pageStartAddress = iter.value[0];
                endAddress = pageStartAddress + pSize;
                break;
            }
        }
        // TODO: Throw an error if table is not found.
        const version = getUint16(iHexMap, endAddress - RegionHeaderOffset.version);
        const tableLength = getUint16(iHexMap, endAddress - RegionHeaderOffset.tableLength);
        const regionCount = getUint16(iHexMap, endAddress - RegionHeaderOffset.regionCount);
        const pageSizeLog2 = getUint16(iHexMap, endAddress - RegionHeaderOffset.pageSizeLog2);
        const pageSize = Math.pow(2, pageSizeLog2);
        const startAddress = endAddress - RegionHeaderOffset.magic1;
        return {
            pageSizeLog2,
            pageSize,
            regionCount,
            tableLength,
            version,
            endAddress,
            startAddress,
        };
    }
    /**
     * Parses a Region rows from a Flash Regions Table inside the Intel Hex memory
     * map, which ends at the provided rowEndAddress.
     *
     * Since the Flash Regions Table is placed at the end of a page, we iterate
     * from the end to the beginning.
     *
     * @param iHexMap - Intel Hex memory map to scan for the Flash Regions Table.
     * @param rowEndAddress - Address at which the row ends (same as the address
     *    where the next row or table header starts).
     * @returns The Region info from the row.
     */
    function getRegionRow(iHexMap, rowEndAddress) {
        const id = getUint8(iHexMap, rowEndAddress - RegionRowOffset.id);
        const hashType = getUint8(iHexMap, rowEndAddress - RegionRowOffset.hashType);
        const hashData = getUint64(iHexMap, rowEndAddress - RegionRowOffset.hashData);
        let hashPointerData = '';
        if (hashType === RegionHashType.pointer) {
            // Pointer to a string in the hex is only 4 bytes instead of 8
            hashPointerData = getString(iHexMap, hashData & 0xffffffff);
        }
        const startPage = getUint16(iHexMap, rowEndAddress - RegionRowOffset.startPage);
        const lengthBytes = getUint32(iHexMap, rowEndAddress - RegionRowOffset.lengthBytes);
        return {
            id,
            startPage,
            lengthBytes,
            hashType,
            hashData,
            hashPointerData,
        };
    }
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
    function getHexMapFlashRegionsData(iHexMap) {
        // TODO: There is currently have some "internal" knowledge here and it's
        // scanning the flash knowing the page size is 4 KBs
        const tableHeader = getTableHeader(iHexMap, 4096);
        const regionRows = {};
        for (let i = 0; i < tableHeader.regionCount; i++) {
            const rowEndAddress = tableHeader.startAddress - i * REGION_ROW_LEN_BYTES;
            const regionRow = getRegionRow(iHexMap, rowEndAddress);
            regionRows[regionRow.id] = regionRow;
        }
        if (!regionRows.hasOwnProperty(RegionId.microPython)) {
            throw new Error('Could not find a MicroPython region in the regions table.');
        }
        if (!regionRows.hasOwnProperty(RegionId.fs)) {
            throw new Error('Could not find a File System region in the regions table.');
        }
        // Have to manually set the start at address 0 even if regions don't cover it
        const runtimeStartAddress = 0;
        let runtimeEndAddress = regionRows[RegionId.microPython].startPage * tableHeader.pageSize +
            regionRows[RegionId.microPython].lengthBytes;
        // The table is placed at the end of the last page used by MicroPython and we
        // need to include it
        runtimeEndAddress = tableHeader.endAddress;
        const uPyVersion = regionRows[RegionId.microPython].hashPointerData;
        const fsStartAddress = regionRows[RegionId.fs].startPage * tableHeader.pageSize;
        const fsEndAddress = fsStartAddress + regionRows[RegionId.fs].lengthBytes;
        return {
            flashPageSize: tableHeader.pageSize,
            flashSize: 512 * 1024,
            flashStartAddress: 0,
            flashEndAddress: 512 * 1024,
            runtimeStartAddress,
            runtimeEndAddress,
            fsStartAddress,
            fsEndAddress,
            uPyVersion,
            deviceVersion: 'V2',
        };
    }

    /**
     * Interprets the data stored in the UICR memory space.
     *
     * For more info:
     * https://microbit-micropython.readthedocs.io/en/latest/devguide/hexformat.html
     *
     * (c) 2019 Micro:bit Educational Foundation and the microbit-fs contributors.
     * SPDX-License-Identifier: MIT
     */
    const DEVICE_INFO = [
        {
            deviceVersion: 'V1',
            magicHeader: 0x17eeb07c,
            flashSize: 256 * 1024,
            fsEnd: 256 * 1024,
        },
        {
            deviceVersion: 'V2',
            magicHeader: 0x47eeb07c,
            flashSize: 512 * 1024,
            fsEnd: 0x73000,
        },
    ];
    const UICR_START = 0x10001000;
    const UICR_CUSTOMER_OFFSET = 0x80;
    const UICR_CUSTOMER_UPY_OFFSET = 0x40;
    const UICR_UPY_START = UICR_START + UICR_CUSTOMER_OFFSET + UICR_CUSTOMER_UPY_OFFSET;
    const UPY_MAGIC_LEN = 4;
    const UPY_END_MARKER_LEN = 4;
    const UPY_PAGE_SIZE_LEN = 4;
    const UPY_START_PAGE_LEN = 2;
    const UPY_PAGES_USED_LEN = 2;
    const UPY_DELIMITER_LEN = 4;
    const UPY_VERSION_LEN = 4;
    const UPY_REGIONS_TERMINATOR_LEN = 4;
    /** UICR Customer area addresses for MicroPython specific data. */
    var MicropythonUicrAddress;
    (function (MicropythonUicrAddress) {
        MicropythonUicrAddress[MicropythonUicrAddress["MagicValue"] = UICR_UPY_START] = "MagicValue";
        MicropythonUicrAddress[MicropythonUicrAddress["EndMarker"] = MicropythonUicrAddress.MagicValue + UPY_MAGIC_LEN] = "EndMarker";
        MicropythonUicrAddress[MicropythonUicrAddress["PageSize"] = MicropythonUicrAddress.EndMarker + UPY_END_MARKER_LEN] = "PageSize";
        MicropythonUicrAddress[MicropythonUicrAddress["StartPage"] = MicropythonUicrAddress.PageSize + UPY_PAGE_SIZE_LEN] = "StartPage";
        MicropythonUicrAddress[MicropythonUicrAddress["PagesUsed"] = MicropythonUicrAddress.StartPage + UPY_START_PAGE_LEN] = "PagesUsed";
        MicropythonUicrAddress[MicropythonUicrAddress["Delimiter"] = MicropythonUicrAddress.PagesUsed + UPY_PAGES_USED_LEN] = "Delimiter";
        MicropythonUicrAddress[MicropythonUicrAddress["VersionLocation"] = MicropythonUicrAddress.Delimiter + UPY_DELIMITER_LEN] = "VersionLocation";
        MicropythonUicrAddress[MicropythonUicrAddress["RegionsTerminator"] = MicropythonUicrAddress.VersionLocation + UPY_REGIONS_TERMINATOR_LEN] = "RegionsTerminator";
        MicropythonUicrAddress[MicropythonUicrAddress["End"] = MicropythonUicrAddress.RegionsTerminator + UPY_VERSION_LEN] = "End";
    })(MicropythonUicrAddress || (MicropythonUicrAddress = {}));
    /**
     * Check if the magic number for the MicroPython UICR data is present in the
     * Intel Hex memory map.
     *
     * @param intelHexMap - Memory map of the Intel Hex data.
     * @return True if the magic number matches, false otherwise.
     */
    function confirmMagicValue(intelHexMap) {
        const readMagicHeader = getMagicValue(intelHexMap);
        for (const device of DEVICE_INFO) {
            if (device.magicHeader === readMagicHeader) {
                return true;
            }
        }
        return false;
    }
    /**
     * Reads the UICR data that contains the Magic Value that indicates the
     * MicroPython presence in the hex data.
     *
     * @param intelHexMap - Memory map of the Intel Hex data.
     * @returns The Magic Value from UICR.
     */
    function getMagicValue(intelHexMap) {
        return getUint32(intelHexMap, MicropythonUicrAddress.MagicValue);
    }
    /**
     * Reads the UICR data from an Intel Hex map and detects the device version.
     *
     * @param intelHexMap - Memory map of the Intel Hex data.
     * @returns The micro:bit board version.
     */
    function getDeviceVersion(intelHexMap) {
        const readMagicHeader = getMagicValue(intelHexMap);
        for (const device of DEVICE_INFO) {
            if (device.magicHeader === readMagicHeader) {
                return device.deviceVersion;
            }
        }
        throw new Error('Cannot find device version, unknown UICR Magic value');
    }
    /**
     * Reads the UICR data from an Intel Hex map and retrieves the flash size.
     *
     * @param intelHexMap - Memory map of the Intel Hex data.
     * @returns The micro:bit flash size.
     */
    function getFlashSize(intelHexMap) {
        const readMagicHeader = getMagicValue(intelHexMap);
        for (const device of DEVICE_INFO) {
            if (device.magicHeader === readMagicHeader) {
                return device.flashSize;
            }
        }
        throw new Error('Cannot find flash size, unknown UICR Magic value');
    }
    /**
     * Reads the UICR data from an Intel Hex map and retrieves the fs end address.
     *
     * @param intelHexMap - Memory map of the Intel Hex data.
     * @returns The micro:bit filesystem end address.
     */
    function getFsEndAddress(intelHexMap) {
        const readMagicHeader = getMagicValue(intelHexMap);
        for (const device of DEVICE_INFO) {
            if (device.magicHeader === readMagicHeader) {
                return device.fsEnd;
            }
        }
        throw new Error('Cannot find fs end address, unknown UICR Magic value');
    }
    /**
     * Reads the UICR data that contains the flash page size.
     *
     * @param intelHexMap - Memory map of the Intel Hex data.
     * @returns The size of each flash page size.
     */
    function getPageSize(intelHexMap) {
        const pageSize = getUint32(intelHexMap, MicropythonUicrAddress.PageSize);
        // Page size is stored as a log base 2
        return Math.pow(2, pageSize);
    }
    /**
     * Reads the UICR data that contains the start page of the MicroPython runtime.
     *
     * @param intelHexMap - Memory map of the Intel Hex data.
     * @returns The start page number of the MicroPython runtime.
     */
    function getStartPage(intelHexMap) {
        return getUint16(intelHexMap, MicropythonUicrAddress.StartPage);
    }
    /**
     * Reads the UICR data that contains the number of flash pages used by the
     * MicroPython runtime.
     *
     * @param intelHexMap - Memory map of the Intel Hex data.
     * @returns The number of pages used by the MicroPython runtime.
     */
    function getPagesUsed(intelHexMap) {
        return getUint16(intelHexMap, MicropythonUicrAddress.PagesUsed);
    }
    /**
     * Reads the UICR data that contains the address of the location in flash where
     * the MicroPython version is stored.
     *
     * @param intelHexMap - Memory map of the Intel Hex data.
     * @returns The address of the location in flash where the MicroPython version
     * is stored.
     */
    function getVersionLocation(intelHexMap) {
        return getUint32(intelHexMap, MicropythonUicrAddress.VersionLocation);
    }
    /**
     * Reads the UICR data from an Intel Hex map and retrieves the MicroPython data.
     *
     * @throws {Error} When the Magic Header is not present.
     *
     * @param intelHexMap - Memory map of the Intel Hex data.
     * @returns Object with the decoded UICR MicroPython data.
     */
    function getHexMapUicrData(intelHexMap) {
        const uicrMap = intelHexMap.slice(UICR_UPY_START);
        if (!confirmMagicValue(uicrMap)) {
            throw new Error('Could not find valid MicroPython UICR data.');
        }
        const flashPageSize = getPageSize(uicrMap);
        const flashSize = getFlashSize(uicrMap);
        const startPage = getStartPage(uicrMap);
        const flashStartAddress = startPage * flashPageSize;
        const flashEndAddress = flashStartAddress + flashSize;
        const pagesUsed = getPagesUsed(uicrMap);
        const runtimeEndAddress = pagesUsed * flashPageSize;
        const versionAddress = getVersionLocation(uicrMap);
        const uPyVersion = getString(intelHexMap, versionAddress);
        const deviceVersion = getDeviceVersion(uicrMap);
        const fsEndAddress = getFsEndAddress(uicrMap);
        return {
            flashPageSize,
            flashSize,
            flashStartAddress,
            flashEndAddress,
            runtimeStartAddress: flashStartAddress,
            runtimeEndAddress,
            fsStartAddress: runtimeEndAddress,
            fsEndAddress,
            uicrStartAddress: MicropythonUicrAddress.MagicValue,
            uicrEndAddress: MicropythonUicrAddress.End,
            uPyVersion,
            deviceVersion,
        };
    }

    /**
     * Retrieves the device information stored inside a MicroPython hex file.
     *
     * (c) 2020 Micro:bit Educational Foundation and the microbit-fs contributors.
     * SPDX-License-Identifier: MIT
     */
    /**
     * Attempts to retrieve the device memory data from an MicroPython Intel Hex
     * memory map.
     *
     * @param {MemoryMap} intelHexMap MicroPython Intel Hex memory map to scan.
     * @returns {DeviceMemInfo} Device data.
     */
    function getHexMapDeviceMemInfo(intelHexMap) {
        let errorMsg = '';
        try {
            return getHexMapUicrData(intelHexMap);
        }
        catch (err) {
            errorMsg += err.message + '\n';
        }
        try {
            return getHexMapFlashRegionsData(intelHexMap);
        }
        catch (err) {
            throw new Error(errorMsg + err.message);
        }
    }

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
    var ChunkMarker;
    (function (ChunkMarker) {
        ChunkMarker[ChunkMarker["Freed"] = 0] = "Freed";
        ChunkMarker[ChunkMarker["PersistentData"] = 253] = "PersistentData";
        ChunkMarker[ChunkMarker["FileStart"] = 254] = "FileStart";
        ChunkMarker[ChunkMarker["Unused"] = 255] = "Unused";
    })(ChunkMarker || (ChunkMarker = {}));
    var ChunkFormatIndex;
    (function (ChunkFormatIndex) {
        ChunkFormatIndex[ChunkFormatIndex["Marker"] = 0] = "Marker";
        ChunkFormatIndex[ChunkFormatIndex["EndOffset"] = 1] = "EndOffset";
        ChunkFormatIndex[ChunkFormatIndex["NameLength"] = 2] = "NameLength";
        ChunkFormatIndex[ChunkFormatIndex["Tail"] = 127] = "Tail";
    })(ChunkFormatIndex || (ChunkFormatIndex = {}));
    /** Sizes for the different parts of the file system chunks. */
    const CHUNK_LEN = 128;
    const CHUNK_MARKER_LEN = 1;
    const CHUNK_TAIL_LEN = 1;
    const CHUNK_DATA_LEN = CHUNK_LEN - CHUNK_MARKER_LEN - CHUNK_TAIL_LEN;
    const CHUNK_HEADER_END_OFFSET_LEN = 1;
    const CHUNK_HEADER_NAME_LEN = 1;
    const MAX_FILENAME_LENGTH = 120;
    /**
     * Chunks are a double linked list with 1-byte pointers and the front marker
     * (previous pointer) cannot have the values listed in the ChunkMarker enum
     */
    const MAX_NUMBER_OF_CHUNKS = 256 - 4;
    /**
     * To speed up the Intel Hex string generation with MicroPython and the
     * filesystem we can cache some of the Intel Hex records and the parsed Memory
     * Map. This function creates an object with cached data that can then be sent
     * to other functions from this module.
     *
     * @param originalIntelHex Intel Hex string with MicroPython to cache.
     * @returns Cached MpFsBuilderCache object.
     */
    function createMpFsBuilderCache(originalIntelHex) {
        const originalMemMap = MemoryMap.fromHex(originalIntelHex);
        const deviceMem = getHexMapDeviceMemInfo(originalMemMap);
        // slice() returns a new MemoryMap with only the MicroPython data, so it will
        // not include the UICR. The End Of File record is removed because this string
        // will be concatenated with the filesystem data any thing else in the MemMap
        const uPyIntelHex = originalMemMap
            .slice(deviceMem.runtimeStartAddress, deviceMem.runtimeEndAddress - deviceMem.runtimeStartAddress)
            .asHexString()
            .replace(':00000001FF', '');
        return {
            originalIntelHex,
            originalMemMap,
            uPyIntelHex,
            uPyEndAddress: deviceMem.runtimeEndAddress,
            fsSize: getMemMapFsSize(originalMemMap),
        };
    }
    /**
     * Scans the file system area inside the Intel Hex data a returns a list of
     * available chunks.
     *
     * @param intelHexMap - Memory map for the MicroPython Intel Hex.
     * @returns List of all unused chunks.
     */
    function getFreeChunks(intelHexMap) {
        const freeChunks = [];
        const startAddress = getStartAddress(intelHexMap);
        const endAddress = getLastPageAddress(intelHexMap);
        let chunkAddr = startAddress;
        let chunkIndex = 1;
        while (chunkAddr < endAddress) {
            const marker = intelHexMap.slicePad(chunkAddr, 1, ChunkMarker.Unused)[0];
            if (marker === ChunkMarker.Unused || marker === ChunkMarker.Freed) {
                freeChunks.push(chunkIndex);
            }
            chunkIndex++;
            chunkAddr += CHUNK_LEN;
        }
        return freeChunks;
    }
    /**
     * Calculates from the input Intel Hex where the MicroPython runtime ends and
     * and where the start of the filesystem would be based on that.
     *
     * @param intelHexMap - Memory map for the MicroPython Intel Hex.
     * @returns Filesystem start address
     */
    function getStartAddress(intelHexMap) {
        const deviceMem = getHexMapDeviceMemInfo(intelHexMap);
        // Calculate the maximum flash space the filesystem can possible take
        const fsMaxSize = CHUNK_LEN * MAX_NUMBER_OF_CHUNKS;
        // The persistent data page is the last page of the filesystem space
        // no need to add it in calculations
        // There might more free space than the filesystem needs, in that case
        // we move the start address down
        const startAddressForMaxFs = getEndAddress(intelHexMap) - fsMaxSize;
        const startAddress = Math.max(deviceMem.fsStartAddress, startAddressForMaxFs);
        // Ensure the start address is aligned with the page size
        if (startAddress % deviceMem.flashPageSize) {
            throw new Error('File system start address from UICR does not align with flash page size.');
        }
        return startAddress;
    }
    /**
     * Calculates the end address for the filesystem.
     *
     * Start from the end of flash, or from the top of appended script if
     * one is included in the Intel Hex data.
     * Then move one page up as it is used for the magnetometer calibration data.
     *
     * @param intelHexMap - Memory map for the MicroPython Intel Hex.
     * @returns End address for the filesystem.
     */
    function getEndAddress(intelHexMap) {
        const deviceMem = getHexMapDeviceMemInfo(intelHexMap);
        let endAddress = deviceMem.fsEndAddress;
        // TODO: Maybe we should move this inside the UICR module to calculate
        // the real fs area in that step
        if (deviceMem.deviceVersion === 'V1') {
            if (isAppendedScriptPresent(intelHexMap)) {
                endAddress = AppendedBlock.StartAdd;
            }
            // In v1 the magnetometer calibration data takes one flash page
            endAddress -= deviceMem.flashPageSize;
        }
        return endAddress;
    }
    /**
     * Calculates the address for the last page available to the filesystem.
     *
     * @param intelHexMap - Memory map for the MicroPython Intel Hex.
     * @returns Memory address where the last filesystem page starts.
     */
    function getLastPageAddress(intelHexMap) {
        const deviceMem = getHexMapDeviceMemInfo(intelHexMap);
        return getEndAddress(intelHexMap) - deviceMem.flashPageSize;
    }
    /**
     * If not present already, it sets the persistent page in flash.
     *
     * This page can be located right below or right on top of the filesystem
     * space.
     *
     * @param intelHexMap - Memory map for the MicroPython Intel Hex.
     */
    function setPersistentPage(intelHexMap) {
        // At the moment we place this persistent page at the end of the filesystem
        // TODO: This could be set to the first or the last page. Check first if it
        //  exists, if it doesn't then randomise its location.
        intelHexMap.set(getLastPageAddress(intelHexMap), new Uint8Array([ChunkMarker.PersistentData]));
    }
    /**
     * Calculate the flash memory address from the chunk index.
     *
     * @param intelHexMap - Memory map for the MicroPython Intel Hex.
     * @param chunkIndex - Index for the chunk to calculate.
     * @returns Address in flash for the chunk.
     */
    function chuckIndexAddress(intelHexMap, chunkIndex) {
        // Chunk index starts at 1, so we need to account for that in the calculation
        return getStartAddress(intelHexMap) + (chunkIndex - 1) * CHUNK_LEN;
    }
    /**
     * Class to contain file data and generate its MicroPython filesystem
     * representation.
     */
    class FsFile {
        /**
         * Create a file.
         *
         * @param filename - Name for the file.
         * @param data - Byte array with the file data.
         */
        constructor(filename, data) {
            Object.defineProperty(this, "_filename", {
                enumerable: true,
                configurable: true,
                writable: true,
                value: void 0
            });
            Object.defineProperty(this, "_filenameBytes", {
                enumerable: true,
                configurable: true,
                writable: true,
                value: void 0
            });
            Object.defineProperty(this, "_dataBytes", {
                enumerable: true,
                configurable: true,
                writable: true,
                value: void 0
            });
            Object.defineProperty(this, "_fsDataBytes", {
                enumerable: true,
                configurable: true,
                writable: true,
                value: void 0
            });
            this._filename = filename;
            this._filenameBytes = strToBytes(filename);
            if (this._filenameBytes.length > MAX_FILENAME_LENGTH) {
                throw new Error(`File name "${filename}" is too long ` +
                    `(max ${MAX_FILENAME_LENGTH} characters).`);
            }
            this._dataBytes = data;
            // Generate a single byte array with the filesystem data bytes.
            // When MicroPython uses up to the last byte of the last chunk it will
            // still consume the next chunk, and leave it blank
            // To replicate the same behaviour we add an extra 0xFF to the data block
            const fileHeader = this._generateFileHeaderBytes();
            this._fsDataBytes = new Uint8Array(fileHeader.length + this._dataBytes.length + 1);
            this._fsDataBytes.set(fileHeader, 0);
            this._fsDataBytes.set(this._dataBytes, fileHeader.length);
            this._fsDataBytes[this._fsDataBytes.length - 1] = 0xff;
        }
        /**
         * Generate an array of file system chunks for all this file content.
         *
         * @throws {Error} When there are not enough chunks available.
         *
         * @param freeChunks - List of available chunks to use.
         * @returns An array of byte arrays, one item per chunk.
         */
        getFsChunks(freeChunks) {
            // Now form the chunks
            const chunks = [];
            let freeChunksIndex = 0;
            let dataIndex = 0;
            // Prepare first chunk where the marker indicates a file start
            let chunk = new Uint8Array(CHUNK_LEN).fill(0xff);
            chunk[ChunkFormatIndex.Marker] = ChunkMarker.FileStart;
            let loopEnd = Math.min(this._fsDataBytes.length, CHUNK_DATA_LEN);
            for (let i = 0; i < loopEnd; i++, dataIndex++) {
                chunk[CHUNK_MARKER_LEN + i] = this._fsDataBytes[dataIndex];
            }
            chunks.push(chunk);
            // The rest of the chunks follow the same pattern
            while (dataIndex < this._fsDataBytes.length) {
                freeChunksIndex++;
                if (freeChunksIndex >= freeChunks.length) {
                    throw new Error(`Not enough space for the ${this._filename} file.`);
                }
                // The previous chunk has to be followed by this one, so add this index
                const previousChunk = chunks[chunks.length - 1];
                previousChunk[ChunkFormatIndex.Tail] = freeChunks[freeChunksIndex];
                chunk = new Uint8Array(CHUNK_LEN).fill(0xff);
                // This chunk Marker points to the previous chunk
                chunk[ChunkFormatIndex.Marker] = freeChunks[freeChunksIndex - 1];
                // Add the data to this chunk
                loopEnd = Math.min(this._fsDataBytes.length - dataIndex, CHUNK_DATA_LEN);
                for (let i = 0; i < loopEnd; i++, dataIndex++) {
                    chunk[CHUNK_MARKER_LEN + i] = this._fsDataBytes[dataIndex];
                }
                chunks.push(chunk);
            }
            return chunks;
        }
        /**
         * Generate a single byte array with the filesystem data for this file.
         *
         * @param freeChunks - List of available chunks to use.
         * @returns A byte array with the data to go straight into flash.
         */
        getFsBytes(freeChunks) {
            const chunks = this.getFsChunks(freeChunks);
            const chunksLen = chunks.length * CHUNK_LEN;
            const fileFsBytes = new Uint8Array(chunksLen);
            for (let i = 0; i < chunks.length; i++) {
                fileFsBytes.set(chunks[i], CHUNK_LEN * i);
            }
            return fileFsBytes;
        }
        /**
         * @returns Size, in bytes, of how much space the file takes in the filesystem
         *     flash memory.
         */
        getFsFileSize() {
            const chunksUsed = Math.ceil(this._fsDataBytes.length / CHUNK_DATA_LEN);
            return chunksUsed * CHUNK_LEN;
        }
        /**
         * Generates a byte array for the file header as expected by the MicroPython
         * file system.
         *
         * @return Byte array with the header data.
         */
        _generateFileHeaderBytes() {
            const headerSize = CHUNK_HEADER_END_OFFSET_LEN +
                CHUNK_HEADER_NAME_LEN +
                this._filenameBytes.length;
            const endOffset = (headerSize + this._dataBytes.length) % CHUNK_DATA_LEN;
            const fileNameOffset = headerSize - this._filenameBytes.length;
            // Format header byte array
            const headerBytes = new Uint8Array(headerSize);
            headerBytes[ChunkFormatIndex.EndOffset - 1] = endOffset;
            headerBytes[ChunkFormatIndex.NameLength - 1] = this._filenameBytes.length;
            for (let i = fileNameOffset; i < headerSize; ++i) {
                headerBytes[i] = this._filenameBytes[i - fileNameOffset];
            }
            return headerBytes;
        }
    }
    /**
     * @returns Size, in bytes, of how much space the file would take in the
     *     MicroPython filesystem.
     */
    function calculateFileSize(filename, data) {
        const file = new FsFile(filename, data);
        return file.getFsFileSize();
    }
    /**
     * Adds a byte array as a file into a MicroPython Memory Map.
     *
     * @throws {Error} When the invalid file name is given.
     * @throws {Error} When the the file doesn't have any data.
     * @throws {Error} When there are issues calculating the file system boundaries.
     * @throws {Error} When there is no space left for the file.
     *
     * @param intelHexMap - Memory map for the MicroPython Intel Hex.
     * @param filename - Name for the file.
     * @param data - Byte array for the file data.
     */
    function addMemMapFile(intelHexMap, filename, data) {
        if (!filename)
            throw new Error('File has to have a file name.');
        if (!data.length)
            throw new Error(`File ${filename} has to contain data.`);
        const freeChunks = getFreeChunks(intelHexMap);
        if (freeChunks.length === 0) {
            throw new Error('There is no storage space left.');
        }
        const chunksStartAddress = chuckIndexAddress(intelHexMap, freeChunks[0]);
        // Create a file, generate and inject filesystem data.
        const fsFile = new FsFile(filename, data);
        const fileFsBytes = fsFile.getFsBytes(freeChunks);
        intelHexMap.set(chunksStartAddress, fileFsBytes);
        setPersistentPage(intelHexMap);
    }
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
    function addIntelHexFiles(intelHex, files, returnBytes = false) {
        let intelHexMap;
        if (typeof intelHex === 'string') {
            intelHexMap = MemoryMap.fromHex(intelHex);
        }
        else {
            intelHexMap = intelHex.clone();
        }
        const deviceMem = getHexMapDeviceMemInfo(intelHexMap);
        Object.keys(files).forEach((filename) => {
            addMemMapFile(intelHexMap, filename, files[filename]);
        });
        return returnBytes
            ? intelHexMap.slicePad(0, deviceMem.flashSize)
            : intelHexMap.asHexString() + '\n';
    }
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
    function generateHexWithFiles(cache, files) {
        const memMapWithFiles = cache.originalMemMap.clone();
        Object.keys(files).forEach((filename) => {
            addMemMapFile(memMapWithFiles, filename, files[filename]);
        });
        return (cache.uPyIntelHex +
            memMapWithFiles.slice(cache.uPyEndAddress).asHexString() +
            '\n');
    }
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
    function getIntelHexFiles(intelHex) {
        let hexMap;
        if (typeof intelHex === 'string') {
            hexMap = MemoryMap.fromHex(intelHex);
        }
        else {
            hexMap = intelHex.clone();
        }
        const startAddress = getStartAddress(hexMap);
        const endAddress = getLastPageAddress(hexMap);
        // TODO: endAddress as the getLastPageAddress works now because this
        // library uses the last page as the "persistent" page, so the filesystem does
        // end there. In reality, the persistent page could be the first or the last
        // page, so we should get the end address as the magnetometer page and then
        // check if the persistent marker is present in the first of last page and
        // take that into account in the memory range calculation.
        // Note that the persistent marker is only present at the top of the page
        // Iterate through the filesystem to collect used chunks and file starts
        const usedChunks = {};
        const startChunkIndexes = [];
        let chunkAddr = startAddress;
        let chunkIndex = 1;
        while (chunkAddr < endAddress) {
            const chunk = hexMap.slicePad(chunkAddr, CHUNK_LEN, ChunkMarker.Unused);
            const marker = chunk[0];
            if (marker !== ChunkMarker.Unused &&
                marker !== ChunkMarker.Freed &&
                marker !== ChunkMarker.PersistentData) {
                usedChunks[chunkIndex] = chunk;
                if (marker === ChunkMarker.FileStart) {
                    startChunkIndexes.push(chunkIndex);
                }
            }
            chunkIndex++;
            chunkAddr += CHUNK_LEN;
        }
        // Go through the list of file-starts, follow the file chunks and collect data
        const files = {};
        for (const startChunkIndex of startChunkIndexes) {
            const startChunk = usedChunks[startChunkIndex];
            const endChunkOffset = startChunk[ChunkFormatIndex.EndOffset];
            const filenameLen = startChunk[ChunkFormatIndex.NameLength];
            // 1st byte is the marker, 2nd is the offset, 3rd is the filename length
            let chunkDataStart = 3 + filenameLen;
            const filename = bytesToStr(startChunk.slice(3, chunkDataStart));
            if (files.hasOwnProperty(filename)) {
                throw new Error(`Found multiple files named: ${filename}.`);
            }
            files[filename] = new Uint8Array(0);
            let currentChunk = startChunk;
            let currentIndex = startChunkIndex;
            // Chunks are basically a double linked list, so invalid data could create
            // an infinite loop. No file should traverse more chunks than available.
            let iterations = Object.keys(usedChunks).length + 1;
            while (iterations--) {
                const nextIndex = currentChunk[ChunkFormatIndex.Tail];
                if (nextIndex === ChunkMarker.Unused) {
                    // The current chunk is the last
                    files[filename] = concatUint8Array(files[filename], currentChunk.slice(chunkDataStart, 1 + endChunkOffset));
                    break;
                }
                else {
                    files[filename] = concatUint8Array(files[filename], currentChunk.slice(chunkDataStart, ChunkFormatIndex.Tail));
                }
                const nextChunk = usedChunks[nextIndex];
                if (!nextChunk) {
                    throw new Error(`Chunk ${currentIndex} points to unused index ${nextIndex}.`);
                }
                if (nextChunk[ChunkFormatIndex.Marker] !== currentIndex) {
                    throw new Error(`Chunk index ${nextIndex} did not link to previous chunk index ${currentIndex}.`);
                }
                currentChunk = nextChunk;
                currentIndex = nextIndex;
                // Start chunk data has a unique start, all others start after marker
                chunkDataStart = 1;
            }
            if (iterations <= 0) {
                // We iterated through chunks more often than available chunks
                throw new Error('Malformed file chunks did not link correctly.');
            }
        }
        return files;
    }
    /**
     * Calculate the MicroPython filesystem size.
     *
     * @param intelHexMap - The MicroPython Intel Hex Memory Map.
     * @returns Size of the filesystem in bytes.
     */
    function getMemMapFsSize(intelHexMap) {
        const deviceMem = getHexMapDeviceMemInfo(intelHexMap);
        const startAddress = getStartAddress(intelHexMap);
        const endAddress = getEndAddress(intelHexMap);
        // One extra page is used as persistent page
        return endAddress - startAddress - deviceMem.flashPageSize;
    }

    /**
     * Class to represent a very simple file.
     *
     * (c) 2019 Micro:bit Educational Foundation and the microbit-fs contributors.
     * SPDX-License-Identifier: MIT
     */
    class SimpleFile {
        /**
         * Create a SimpleFile.
         *
         * @throws {Error} When an invalid filename is provided.
         * @throws {Error} When invalid file data is provided.
         *
         * @param filename - Name for the file.
         * @param data - String or byte array with the file data.
         */
        constructor(filename, data) {
            Object.defineProperty(this, "filename", {
                enumerable: true,
                configurable: true,
                writable: true,
                value: void 0
            });
            Object.defineProperty(this, "_dataBytes", {
                enumerable: true,
                configurable: true,
                writable: true,
                value: void 0
            });
            if (!filename) {
                throw new Error('File was not provided a valid filename.');
            }
            if (!data) {
                throw new Error(`File ${filename} does not have valid content.`);
            }
            this.filename = filename;
            if (typeof data === 'string') {
                this._dataBytes = strToBytes(data);
            }
            else if (data instanceof Uint8Array) {
                this._dataBytes = data;
            }
            else {
                throw new Error('File data type must be a string or Uint8Array.');
            }
        }
        getText() {
            return bytesToStr(this._dataBytes);
        }
        getBytes() {
            return this._dataBytes;
        }
    }

    /**
     * Filesystem management for MicroPython hex files.
     *
     * (c) 2019 Micro:bit Educational Foundation and the microbit-fs contributors.
     * SPDX-License-Identifier: MIT
     */
    /**
     * The Board ID is used to identify the different targets from a Universal Hex.
     * In this case the target represents a micro:bit version.
     * For micro:bit V1 (v1.3, v1.3B and v1.5) the `boardId` is `0x9900`, and for
     * V2 `0x9903`.
     * This is being re-exported from the @microbit/microbit-universal-hex package.
     */
    var microbitBoardId = microbitBoardId$1;
    /**
     * Manage filesystem files in one or multiple MicroPython hex files.
     *
     * @public
     */
    class MicropythonFsHex {
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
        constructor(intelHex, { maxFsSize = 0 } = {}) {
            Object.defineProperty(this, "_uPyFsBuilderCache", {
                enumerable: true,
                configurable: true,
                writable: true,
                value: []
            });
            Object.defineProperty(this, "_files", {
                enumerable: true,
                configurable: true,
                writable: true,
                value: {}
            });
            Object.defineProperty(this, "_storageSize", {
                enumerable: true,
                configurable: true,
                writable: true,
                value: 0
            });
            const hexWithIdArray = Array.isArray(intelHex)
                ? intelHex
                : [
                    {
                        hex: intelHex,
                        boardId: 0x0000,
                    },
                ];
            // Generate and store the MicroPython Builder caches
            let minFsSize = Infinity;
            hexWithIdArray.forEach((hexWithId) => {
                if (!hexWithId.hex) {
                    throw new Error('Invalid MicroPython hex.');
                }
                const builderCache = createMpFsBuilderCache(hexWithId.hex);
                const thisBuilderCache = {
                    originalIntelHex: builderCache.originalIntelHex,
                    originalMemMap: builderCache.originalMemMap,
                    uPyEndAddress: builderCache.uPyEndAddress,
                    uPyIntelHex: builderCache.uPyIntelHex,
                    fsSize: builderCache.fsSize,
                    boardId: hexWithId.boardId,
                };
                this._uPyFsBuilderCache.push(thisBuilderCache);
                minFsSize = Math.min(minFsSize, thisBuilderCache.fsSize);
            });
            this.setStorageSize(maxFsSize || minFsSize);
            // Check if there are files in any of the input hex
            this._uPyFsBuilderCache.forEach((builderCache) => {
                const hexFiles = getIntelHexFiles(builderCache.originalMemMap);
                if (Object.keys(hexFiles).length) {
                    throw new Error('There are files in the MicropythonFsHex constructor hex file input.');
                }
            });
        }
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
        create(filename, content) {
            if (this.exists(filename)) {
                throw new Error('File already exists.');
            }
            this.write(filename, content);
        }
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
        write(filename, content) {
            this._files[filename] = new SimpleFile(filename, content);
        }
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        append(filename, content) {
            if (!filename) {
                throw new Error('Invalid filename.');
            }
            if (!this.exists(filename)) {
                throw new Error(`File "${filename}" does not exist.`);
            }
            // TODO: Implement this.
            throw new Error('Append operation not yet implemented.');
        }
        /**
         * Read the text from a file.
         *
         * @throws {Error} When invalid file name is provided.
         * @throws {Error} When file is not in the file system.
         *
         * @param filename - Name of the file to read.
         * @returns Text from the file.
         */
        read(filename) {
            if (!filename) {
                throw new Error('Invalid filename.');
            }
            if (!this.exists(filename)) {
                throw new Error(`File "${filename}" does not exist.`);
            }
            return this._files[filename].getText();
        }
        /**
         * Read the bytes from a file.
         *
         * @throws {Error} When invalid file name is provided.
         * @throws {Error} When file is not in the file system.
         *
         * @param filename - Name of the file to read.
         * @returns Byte array from the file.
         */
        readBytes(filename) {
            if (!filename) {
                throw new Error('Invalid filename.');
            }
            if (!this.exists(filename)) {
                throw new Error(`File "${filename}" does not exist.`);
            }
            return this._files[filename].getBytes();
        }
        /**
         * Delete a file from the file system.
         *
         * @throws {Error} When invalid file name is provided.
         * @throws {Error} When the file doesn't exist.
         *
         * @param filename - Name of the file to delete.
         */
        remove(filename) {
            if (!filename) {
                throw new Error('Invalid filename.');
            }
            if (!this.exists(filename)) {
                throw new Error(`File "${filename}" does not exist.`);
            }
            delete this._files[filename];
        }
        /**
         * Check if a file is already present in the file system.
         *
         * @param filename - Name for the file to check.
         * @returns True if it exists, false otherwise.
         */
        exists(filename) {
            return this._files.hasOwnProperty(filename);
        }
        /**
         * Returns the size of a file in bytes.
         *
         * @throws {Error} When invalid file name is provided.
         * @throws {Error} When the file doesn't exist.
         *
         * @param filename - Name for the file to check.
         * @returns Size file size in bytes.
         */
        size(filename) {
            if (!filename) {
                throw new Error(`Invalid filename: ${filename}`);
            }
            if (!this.exists(filename)) {
                throw new Error(`File "${filename}" does not exist.`);
            }
            return calculateFileSize(this._files[filename].filename, this._files[filename].getBytes());
        }
        /**
         * @returns A list all the files in the file system.
         */
        ls() {
            const files = [];
            Object.values(this._files).forEach((value) => files.push(value.filename));
            return files;
        }
        /**
         * Sets a storage size limit. Must be smaller than available space in
         * MicroPython.
         *
         * @param {number} size - Size in bytes for the filesystem.
         */
        setStorageSize(size) {
            let minFsSize = Infinity;
            this._uPyFsBuilderCache.forEach((builderCache) => {
                minFsSize = Math.min(minFsSize, builderCache.fsSize);
            });
            if (size > minFsSize) {
                throw new Error('Storage size limit provided is larger than size available in the MicroPython hex.');
            }
            this._storageSize = size;
        }
        /**
         * The available filesystem total size either calculated by the MicroPython
         * hex or the max storage size limit has been set.
         *
         * @returns Size of the filesystem in bytes.
         */
        getStorageSize() {
            return this._storageSize;
        }
        /**
         * @returns The total number of bytes currently used by files in the file system.
         */
        getStorageUsed() {
            return Object.values(this._files).reduce((accumulator, current) => accumulator + this.size(current.filename), 0);
        }
        /**
         * @returns The remaining storage of the file system in bytes.
         */
        getStorageRemaining() {
            return this.getStorageSize() - this.getStorageUsed();
        }
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
        importFilesFromIntelHex(intelHex, { overwrite = false, formatFirst = false } = {}) {
            const files = getIntelHexFiles(intelHex);
            if (!Object.keys(files).length) {
                throw new Error('Intel Hex does not have any files to import');
            }
            if (formatFirst) {
                this._files = {};
            }
            const existingFiles = [];
            Object.keys(files).forEach((filename) => {
                if (!overwrite && this.exists(filename)) {
                    existingFiles.push(filename);
                }
                else {
                    this.write(filename, files[filename]);
                }
            });
            // Only throw the error at the end so that all other files are imported
            if (existingFiles.length) {
                throw new Error(`Files "${existingFiles}" from hex already exists.`);
            }
            return Object.keys(files);
        }
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
        importFilesFromUniversalHex(universalHex, { overwrite = false, formatFirst = false } = {}) {
            if (!isUniversalHex(universalHex)) {
                throw new Error('Universal Hex provided is invalid.');
            }
            const hexWithIds = separateUniversalHex(universalHex);
            const allFileGroups = [];
            hexWithIds.forEach((hexWithId) => {
                const fileGroup = getIntelHexFiles(hexWithId.hex);
                if (!Object.keys(fileGroup).length) {
                    throw new Error(`Hex with ID ${hexWithId.boardId} from Universal Hex does not have any files to import`);
                }
                allFileGroups.push(fileGroup);
            });
            // Ensure all hexes have the same files
            allFileGroups.forEach((fileGroup) => {
                // Create new array without this current group
                const compareFileGroups = allFileGroups.filter((v) => v !== fileGroup);
                // Check that all files in this group are in all the others
                for (const [fileName, fileContent] of Object.entries(fileGroup)) {
                    compareFileGroups.forEach((compareGroup) => {
                        if (!compareGroup.hasOwnProperty(fileName) ||
                            !areUint8ArraysEqual(compareGroup[fileName], fileContent)) {
                            throw new Error('Mismatch in the different Hexes inside the Universal Hex');
                        }
                    });
                }
            });
            // If we reached this point all file groups are the same and we can use any
            const files = allFileGroups[0];
            if (formatFirst) {
                this._files = {};
            }
            const existingFiles = [];
            Object.keys(files).forEach((filename) => {
                if (!overwrite && this.exists(filename)) {
                    existingFiles.push(filename);
                }
                else {
                    this.write(filename, files[filename]);
                }
            });
            // Only throw the error at the end so that all other files are imported
            if (existingFiles.length) {
                throw new Error(`Files "${existingFiles}" from hex already exists.`);
            }
            return Object.keys(files);
        }
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
        importFilesFromHex(hexStr, options = {}) {
            return isUniversalHex(hexStr)
                ? this.importFilesFromUniversalHex(hexStr, options)
                : this.importFilesFromIntelHex(hexStr, options);
        }
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
        getIntelHex(boardId) {
            if (this.getStorageRemaining() < 0) {
                throw new Error('There is no storage space left.');
            }
            const files = {};
            Object.values(this._files).forEach((file) => {
                files[file.filename] = file.getBytes();
            });
            if (boardId === undefined) {
                if (this._uPyFsBuilderCache.length === 1) {
                    return generateHexWithFiles(this._uPyFsBuilderCache[0], files);
                }
                else {
                    throw new Error('The Board ID must be specified if there are multiple MicroPythons.');
                }
            }
            for (const builderCache of this._uPyFsBuilderCache) {
                if (builderCache.boardId === boardId) {
                    return generateHexWithFiles(builderCache, files);
                }
            }
            // If we reach this point we could not find the board ID
            throw new Error('Board ID requested not found.');
        }
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
        getIntelHexBytes(boardId) {
            if (this.getStorageRemaining() < 0) {
                throw new Error('There is no storage space left.');
            }
            const files = {};
            Object.values(this._files).forEach((file) => {
                files[file.filename] = file.getBytes();
            });
            if (boardId === undefined) {
                if (this._uPyFsBuilderCache.length === 1) {
                    return addIntelHexFiles(this._uPyFsBuilderCache[0].originalMemMap, files, true);
                }
                else {
                    throw new Error('The Board ID must be specified if there are multiple MicroPythons.');
                }
            }
            for (const builderCache of this._uPyFsBuilderCache) {
                if (builderCache.boardId === boardId) {
                    return addIntelHexFiles(builderCache.originalMemMap, files, true);
                }
            }
            // If we reach this point we could not find the board ID
            throw new Error('Board ID requested not found.');
        }
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
        getUniversalHex() {
            if (this._uPyFsBuilderCache.length === 1) {
                throw new Error('MicropythonFsHex constructor must have more than one MicroPython ' +
                    'Intel Hex to generate a Universal Hex.');
            }
            const iHexWithIds = [];
            this._uPyFsBuilderCache.forEach((builderCache) => {
                iHexWithIds.push({
                    hex: this.getIntelHex(builderCache.boardId),
                    boardId: builderCache.boardId,
                });
            });
            return createUniversalHex(iHexWithIds);
        }
    }

    // Import microbit-fs library

    /**
     * Build Universal Hex from V1 and V2 firmware with Python code
     * @param {string} v1Hex - V1 firmware hex content
     * @param {string} v2Hex - V2 firmware hex content  
     * @param {string} mainPy - Python code to embed
     * @returns {string} Universal Hex content
     */
    function buildUniversalHex(v1Hex, v2Hex, mainPy) {
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
    function validateHex(hex) {
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
    function getEstimatedSize(v1Hex, v2Hex, mainPy) {
      const v1Size = v1Hex ? v1Hex.length : 0;
      const v2Size = v2Hex ? v2Hex.length : 0;
      const pySize = mainPy ? mainPy.length : 0;
      
      // Universal Hex is typically 1.7-1.9MB
      // This is a rough estimation
      return Math.max(v1Size, v2Size) + pySize + 100000; // Add overhead
    }

    exports.buildUniversalHex = buildUniversalHex;
    exports.getEstimatedSize = getEstimatedSize;
    exports.validateHex = validateHex;

    return exports;

})({});
