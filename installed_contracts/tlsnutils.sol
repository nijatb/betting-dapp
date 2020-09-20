pragma solidity ^0.4.11;

library tlsnutils{

    using bytesutils for *;

    /*
     * @dev Returns the complete conversation part of one peer (all generator records).
     * @param proof The proof.
     * @param conversation_part 0 = Requester(Client), 1 = Generator(Server).
     * @return The response as a bytestring.
    */
    function getConversationPart(bytes memory proof, bytes1 conversation_part) private returns(bytes){
        bytes memory response = "";
        uint16 readPos = 96;
        // Skipping the certificate chain
        readPos += uint16(proof[26])+256*uint16(proof[27]);
        bytes1 generator_originated;
        // Parse one record after another ( i < num_proof_nodes )
        for(uint16 i = 0; i < uint16(proof[6])+256*uint16(proof[7]); i++){

            // Assume the request is in the first record
            bytes2 len_record; // Length of the record
            assembly { len_record := mload(add(proof,add(readPos,33))) }

            uint16 tmplen = uint16(len_record[0])+256*uint16(len_record[1]);

            generator_originated = proof[readPos+3];

            // Skip node, type, content len and generator info
            readPos += 4;

            if(generator_originated == conversation_part){
                var chunk = proof.toSlice(readPos).truncate(tmplen);
                response = response.toSlice().concat(chunk);
            }
            readPos += tmplen + 16;
        }
        return response;
    }



    /*
     * @dev Returns the complete request (all requester records).
     * @param proof The proof.
     * @return The request as a bytestring.
    */
    function getRequest(bytes memory proof) internal returns(bytes){
        return getConversationPart(proof, 0);
    }


    /*
     * @dev Returns the complete response (all generator records).
     * @param proof The proof.
     * @return The response as a bytestring.
    */
    function getResponse(bytes memory proof) internal returns(bytes){
        return getConversationPart(proof, 1);
    }



    /*
     * @dev Returns the HTTP body.
     * @param proof The proof.
     * @return The HTTP body in case the request was valid. (200 OK)
    */
    function getHTTPBody(bytes memory proof) internal returns(bytes){
        bytes memory response = getResponse(proof);
        bytesutils.slice memory code = response.toSlice().truncate(15);
        require(code.equals("HTTP/1.1 200 OK".toSlice()));
        bytesutils.slice memory body = response.toSlice().find("\r\n\r\n".toSlice());
        body.addOffset(4);
        return body.toBytes();
    }


    /*
     * @dev Returns HTTP Host inside the request
     * @param proof The proof.
     * @return The Host as a bytestring.
    */
    function getHost(bytes memory proof) internal returns(bytes){
        bytesutils.slice memory request = getRequest(proof).toSlice();
        // Search in Headers
        request = request.split("\r\n\r\n".toSlice());
        // Find host header
        request.find("Host:".toSlice());
        request.addOffset(5);
        // Until newline
        request = request.split("\r\n".toSlice());
        while(request.startsWith(" ".toSlice())){
            request.addOffset(1);
        }
		require(request.len() > 0);
        return request.toBytes();
    }

    /*
     * @dev Returns the requested URL for HTTP
     * @param proof The proof.
     * @return The request as a bytestring. Empty string on error.
    */
    function getHTTPRequestURL(bytes memory proof) internal returns(bytes){
        bytes memory request = getRequest(proof);
        bytesutils.slice memory slice = request.toSlice();
        bytesutils.slice memory delim = " ".toSlice();
        // Check the method is GET
        bytesutils.slice memory method = slice.split(delim);
        require(method.equals("GET".toSlice()));
        // Return the URL
        return slice.split(delim).toBytes();
    }

    /*
     * @dev Verify a proof signed by tls-n.org.
     * @param proof The proof.
     * @return True iff valid.
    */
	function verifyProof(bytes memory proof) returns(bool) {
		uint256 qx = 0x0de2583dc1b70c4d17936f6ca4d2a07aa2aba06b76a97e60e62af286adc1cc09; //public key x-coordinate signer
		uint256 qy = 0x68ba8822c94e79903406a002f4bc6a982d1b473f109debb2aa020c66f642144a; //public key y-coordinate signer
		return verifyProof(proof, qx, qy);
	}

    /*
     * @dev Verify a proof signed by the specified key.
     * @param proof The proof.
     * @return True iff valid.
    */
	function verifyProof(bytes memory proof, uint256 qx, uint256 qy) returns(bool) {
		bytes32 m; // Evidence Hash in bytes32
		uint256 e; // Evidence Hash in uint256
		uint256 sig_r; //signature parameter
		uint256 sig_s; //signature parameter

		// Returns ECC signature parts and the evidence hash
		(sig_r, sig_s, m) = parseProof(proof);

		// Convert evidence hash to uint
		e = uint256(m);

		// Verify signature
		return ECMath.ecdsaverify(qx, qy, e, sig_r, sig_s);

	}

    /*
     * @dev Parses the provided proof and returns the signature parts and the evidence hash.
	 * For 64-byte ECC proofs with SHA256.
     * @param proof The proof.
     * @return sig_r, sig_s: signature parts and hashchain: the final evidence hash.
    */
  function parseProof(bytes memory proof) returns(uint256 sig_r, uint256 sig_s, bytes32 hashchain) {

      uint16 readPos = 0; // Initialize index in proof bytes array
      bytes16 times; // Contains Timestamps for signature validation
	  bytes2 len_record; // Length of the record
	  bytes1 generator_originated; // Boolean whether originated by generator
	  bytes memory chunk; // One chunk for hashing
	  bytes16 saltsecret; // Salt secret from proof

      // Parse times
      assembly {
        times := mload(add(proof, 40))
      }
      readPos += 32; //update readPos, skip parameters

    assembly {
        sig_r := mload(add(proof,64))
        sig_s := mload(add(proof,96))
	    readPos := add(readPos, 64)
    }

      // Skipping the certificate chain
      readPos += uint16(proof[26])+256*uint16(proof[27]);

      // Parse one record after another ( i < num_proof_nodes )
	  for(uint16 i = 0; i < uint16(proof[6])+256*uint16(proof[7]); i++){
			// Get the Record length as a byte array
			assembly { len_record := mload(add(proof,add(readPos,33))) }
			// Convert the record length into a number
			uint16 tmplen = uint16(len_record[0])+256*uint16(len_record[1]);
			// Parse generator information
			generator_originated = proof[readPos+3];
			// Update readPos
			readPos += 4;
			// Set chunk pointer
			assembly { chunk := add(proof,readPos) }
			// Set length of chunks
			assembly { mstore(chunk, tmplen) }
			// Load saltsecret
			assembly { saltsecret := mload(add(proof,add(readPos,add(tmplen,32)))) }
			// Root hash
			bytes32 hash = sha256(saltsecret,chunk,uint8(0),len_record,generator_originated);
			// Hash chain
			if(i == 0){
				hashchain = sha256(uint8(1),hash);
			}else{
				hashchain = sha256(uint8(1),hashchain,hash);
			}
			// Jump over record and salt secret
			readPos += tmplen + 16;
		}
		// Compute Evidence Hash
		// Load chunk size and salt size
		bytes4 test; // Temporarily contains salt size and chunk size
		assembly { test := mload(add(proof,34)) }
		// Compute final hash chain
		hashchain = sha256(hashchain, times, test, 0x04000000);
    }
}

library bytesutils {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire bytes.
     * @param self The bytes to make a slice from.
     * @return A newly allocated slice containing the entire bytes.
     */
    function toSlice(bytes self) internal returns (slice) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(self.length, ptr);
    }

    function addOffset(slice self, uint32 offset) internal returns (slice) {
        require(offset <= self._len);
        self._ptr += offset;
        self._len -= offset;
        return self;
    }

    /*
     * @dev Returns a slice containing the entire bytes.
     * @param self The bytes to make a slice from.
     * @param offset The offset within the bytestring.
     * @return A newly allocated slice containing the entire bytes.
     */
    function toSlice(bytes self, uint32 offset) internal returns (slice) {
        slice memory ret = toSlice(self);
        return addOffset(ret, offset);
    }


    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (self & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-termintaed utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal returns (slice ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice self) internal returns (slice) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new bytestring.
     * @param self The slice to copy.
     * @return A newly allocated bytestring containing the slice's text.
     */
    function toBytes(slice self) internal returns (bytes) {
        var ret = new bytes(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }


    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice self) internal returns (string) {
        var ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }



    /*
     * @dev Returns the length in bytes of the slice.
     * @param self The slice to operate on.
     * @return The length of the slice in bytes.
     */
    function len(slice self) internal returns (uint) {
        return self._len;
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice self) internal returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice self, slice other) internal returns (int) {
        uint shortest = self._len;
        if (other._len < self._len)
            shortest = other._len;

        var selfptr = self._ptr;
        var otherptr = other._ptr;
        for (uint idx = 0; idx < shortest; idx += 32) {
            uint a;
            uint b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                var diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice self, slice other) internal returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice self, slice rune) internal returns (slice) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

		// Byte runes are always of length 1
        uint len = 1;

        self._ptr += len;
        self._len -= len;
        rune._len = len;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice self) internal returns (slice ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice self) internal returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint div = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        ret = word / div;

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice self) internal returns (bytes32 ret) {
        assembly {
            ret := sha3(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns the sha-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function slicesha256(slice self) internal returns (bytes32) {
        bytes memory x = toBytes(self);
        return sha256(x);
    }


    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice self, slice needle) internal returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let len := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(sha3(selfptr, len), sha3(needleptr, len))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice self, slice needle) internal returns (slice) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let len := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(sha3(selfptr, len), sha3(needleptr, len))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice self, slice needle) internal returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        var selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let len := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(sha3(selfptr, len), sha3(needleptr, len))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice self, slice needle) internal returns (slice) {
        if (self._len < needle._len) {
            return self;
        }

        var selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let len := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(sha3(selfptr, len), sha3(needleptr, len))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private returns (uint) {
        uint ptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                // Optimized assembly for 68 gas per byte on short strings
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    let end := add(selfptr, sub(selflen, needlelen))
                    ptr := selfptr
                    loop:
                    jumpi(exit, eq(and(mload(ptr), mask), needledata))
                    ptr := add(ptr, 1)
                    jumpi(loop, lt(sub(ptr, 1), end))
                    ptr := add(selfptr, selflen)
                    exit:
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }
                ptr = selfptr;
                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                // Optimized assembly for 69 gas per byte on short strings
                assembly {
                    let mask := not(sub(exp(2, mul(8, sub(32, needlelen))), 1))
                    let needledata := and(mload(needleptr), mask)
                    ptr := add(selfptr, sub(selflen, needlelen))
                    loop:
                    jumpi(ret, eq(and(mload(ptr), mask), needledata))
                    ptr := sub(ptr, 1)
                    jumpi(loop, gt(add(ptr, 1), selfptr))
                    ptr := selfptr
                    jump(exit)
                    ret:
                    ptr := add(ptr, needlelen)
                    exit:
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice self, slice needle) internal returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the last occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice self, slice needle) internal returns (slice) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice self, slice needle, slice token) internal returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice self, slice needle) internal returns (slice token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice self, slice needle, slice token) internal returns (slice) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice self, slice needle) internal returns (slice token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice self, slice needle) internal returns (uint count) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            count++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice self, slice needle) internal returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated bytestring containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two bytestrings.
     */
    function concat(slice self, slice other) internal returns (bytes) {
        var ret = new bytes(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Truncates a slice to a specified new length.
     * @param self The slice to truncate.
     * @param new_len The new length.
     * @return The truncated slice.
     */
    function truncate(slice self, uint new_len) internal returns (slice){
        if(self._len > new_len){
            self._len = new_len;
        }
        return self;
    }


    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated bytestring.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated bytestring containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice self, slice[] parts) internal returns (bytes) {
        if (parts.length == 0)
            return "";

        uint len = self._len * (parts.length - 1);
        for(uint i = 0; i < parts.length; i++)
            len += parts[i]._len;

        var ret = new bytes(len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        for(i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

// Library for secp256r1
library ECMath {


  //curve parameters secp256r1
  uint256 constant a=115792089210356248762697446949407573530086143415290314195533631308867097853948;
  uint256 constant b=41058363725152142129326129780047268409114441015993725554835256314039467401291;
  uint256 constant gx=48439561293906451759052585252797914202762949526041747995844080717082404635286;
  uint256 constant gy=36134250956749795798585127919587881956611106672985015071877198253568414405109;
  uint256 constant p=115792089210356248762697446949407573530086143415290314195533631308867097853951;
  uint256 constant n=115792089210356248762697446949407573529996955224135760342422259061068512044369;
  uint256 constant h=1;


  function ecdsaverify(uint256 qx, uint256 qy, uint256 e, uint256 r, uint256 s) returns (bool) {

    if (!isPoint(qx,qy)) {
      return false;
    }

    //temporary variables
    uint256 w;
    uint256 u1;
    uint256 u2;
    uint256[3] memory T1;
    uint256[3] memory T2;
    w=invmod(s,n);
    u1=mulmod(e,w,n);
    u2=mulmod(r,w,n);
    T1=ecmul([gx,gy,1],u1);
    T2=ecmul([qx,qy,1],u2);
    T2=ecadd(T1,T2);
    if (r==JtoA(T2)[0]) {
      return true;
    }
    return false;
  }

  //function checks if point (x1,y1) is on curve, x1 and y1 affine coordinate parameters
  function isPoint(uint256 x1, uint256 y1) private returns (bool) {
    //point fulfills y^2=x^3+ax+b?
    if (mulmod(y1,y1,p) == addmod(mulmod(x1,mulmod(x1,x1,p),p),addmod(mulmod(a,x1,p),b,p),p)) {
      return (true);
    }
    else {
      return (false);
    }
  }

  // point addition for elliptic curve in jacobian coordinates
  // formula from https://en.wikibooks.org/wiki/Cryptography/Prime_Curve/Jacobian_Coordinates
  function ecadd(uint256[3] P, uint256[3] Q) private returns (uint256[3] R) {

    uint256 u1;
    uint256 u2;
    uint256 s1;
    uint256 s2;

    if (Q[0]==0 && Q[1]==0 && Q[2]==0) {
      return P;
    }

    u1 = mulmod(P[0],mulmod(Q[2],Q[2],p),p);
    u2 = mulmod(Q[0],mulmod(P[2],P[2],p),p);
    s1 = mulmod(P[1],mulmod(mulmod(Q[2],Q[2],p),Q[2],p),p);
    s2 = mulmod(Q[1],mulmod(mulmod(P[2],P[2],p),P[2],p),p);

    if (u1==u2) {
      if (s1 != s2) {
        R[0]=1;
        R[1]=1;
        R[2]=0;
        return R;
      }
      else {
        return ecdouble(P);
      }
    }

    uint256 h;
    uint256 r;

    h = addmod(u2,(p-u1),p);
    r = addmod(s2,(p-s1),p);

    R[0] = addmod(addmod(mulmod(r,r,p),(p-mulmod(h,mulmod(h,h,p),p)),p),(p-mulmod(2,mulmod(u1,mulmod(h,h,p),p),p)),p);
    R[1] = addmod(mulmod(r,addmod(mulmod(u1,mulmod(h,h,p),p),(p-R[0]),p),p),(p-mulmod(s1,mulmod(h,mulmod(h,h,p),p),p)),p);
    R[2] = mulmod(h,mulmod(P[2],Q[2],p),p);

    return (R);
  }

  //point doubling for elliptic curve in jacobian coordinates
  //formula from https://en.wikibooks.org/wiki/Cryptography/Prime_Curve/Jacobian_Coordinates
  function ecdouble(uint256[3] P) private returns(uint256[3] R){

    //return point at infinity
    if (P[1]==0) {
      R[0]=1;
      R[1]=1;
      R[2]=0;
      return (R);
    }

    uint256 m;
    uint256 s;

    s = mulmod(4,mulmod(P[0],mulmod(P[1],P[1],p),p),p);
    m = addmod(mulmod(3,mulmod(P[0],P[0],p),p),mulmod(a,mulmod(mulmod(P[2],P[2],p),mulmod(P[2],P[2],p),p),p),p);
    R[0] = addmod(mulmod(m,m,p),(p-mulmod(s,2,p)),p);
    R[1] = addmod(mulmod(m,addmod(s,(p-R[0]),p),p),(p-mulmod(8,mulmod(mulmod(P[1],P[1],p),mulmod(P[1],P[1],p),p),p)),p);
    R[2] = mulmod(2,mulmod(P[1],P[2],p),p);

    return (R);

  }

  // function for elliptic curve multiplication in jacobian coordinates using Double-and-add method
  function ecmul(uint256[3] P, uint256 d) private returns (uint256[3] R) {

    R[0]=0;
    R[1]=0;
    R[2]=0;

    //return (0,0) if d=0 or (x1,y1)=(0,0)
    if (d == 0 || ((P[0]==0) && (P[1]==0)) ) {
      return (R);
    }
    uint256[3] memory T;
    T[0]=P[0]; //x-coordinate temp
    T[1]=P[1]; //y-coordinate temp
    T[2]=P[2]; //z-coordiante temp

    while (d != 0) {
      if ((d & 1) == 1) {  //if last bit is 1 add T to result
        R = ecadd(T,R);
      }
      T = ecdouble(T);    //double temporary coordinates
      d=d/2;              //"cut off" last bit
    }

    return R;
  }

  //jacobian to affine coordinates transfomration
  function JtoA(uint256[3] P) private returns (uint256[2] Pnew) {
    uint zInv = invmod(P[2],p);
    uint zInv2 = mulmod(zInv, zInv, p);
    Pnew[0] = mulmod(P[0], zInv2, p);
    Pnew[1] = mulmod(P[1], mulmod(zInv,zInv2,p), p);
  }

  //computing inverse by using euclidean algorithm
  function invmod(uint256 a, uint p) private returns(uint256 invA) {
    uint256 t=0;
    uint256 newT=1;
    uint256 r=p;
    uint256 newR=a;
    uint256 q;
    while (newR != 0) {
      q = r / newR;

      (t, newT) = (newT, addmod(t , (p - mulmod(q, newT,p)) , p));
      (r, newR) = (newR, r - q * newR );
    }

    return t;
  }

}
