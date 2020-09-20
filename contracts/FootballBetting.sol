pragma solidity ^0.4.15;

library JsmnSolLib {

    enum JsmnType { UNDEFINED, OBJECT, ARRAY, STRING, PRIMITIVE }

    uint constant RETURN_SUCCESS = 0;
    uint constant RETURN_ERROR_INVALID_JSON = 1;
    uint constant RETURN_ERROR_PART = 2;
    uint constant RETURN_ERROR_NO_MEM = 3;

    struct Token {
        JsmnType jsmnType;
        uint start;
        bool startSet;
        uint end;
        bool endSet;
        uint8 size;
    }

    struct Parser {
        uint pos;
        uint toknext;
        int toksuper;
    }

    function init(uint length) internal returns (Parser, Token[]) {
        Parser memory p = Parser(0, 0, -1);
        Token[] memory t = new Token[](length);
        return (p, t);
    }

    function allocateToken(Parser parser, Token[] tokens) internal returns (bool, Token) {
        if (parser.toknext >= tokens.length) {
            // no more space in tokens
            return (false, tokens[tokens.length-1]);
        }
        Token memory token = Token(JsmnType.UNDEFINED, 0, false, 0, false, 0);
        tokens[parser.toknext] = token;
        parser.toknext++;
        return (true, token);
    }

    function fillToken(Token token, JsmnType jsmnType, uint start, uint end) internal {
        token.jsmnType = jsmnType;
        token.start = start;
        token.startSet = true;
        token.end = end;
        token.endSet = true;
        token.size = 0;
    }

    function parseString(Parser parser, Token[] tokens, bytes s) internal returns (uint) {
        uint start = parser.pos;
        parser.pos++;

        for (; parser.pos<s.length; parser.pos++) {
            bytes1 c = s[parser.pos];

            // Quote -> end of string
            if (c == '"') {
                var (success, token) = allocateToken(parser, tokens);
                if (!success) {
                    parser.pos = start;
                    return RETURN_ERROR_NO_MEM;
                }
                fillToken(token, JsmnType.STRING, start+1, parser.pos);
                return RETURN_SUCCESS;
            }

            if (c == 92 && parser.pos + 1 < s.length) {
                // handle escaped characters: skip over it
                parser.pos++;
                if (s[parser.pos] == '\"' || s[parser.pos] == '/' || s[parser.pos] == '\\'
                    || s[parser.pos] == 'f' || s[parser.pos] == 'r' || s[parser.pos] == 'n'
                    || s[parser.pos] == 'b' || s[parser.pos] == 't') {
                        continue;
                        } else {
                            // all other values are INVALID
                            parser.pos = start;
                            return(RETURN_ERROR_INVALID_JSON);
                        }
                    }
            }
        parser.pos = start;
        return RETURN_ERROR_PART;
    }

    function parsePrimitive(Parser parser, Token[] tokens, bytes s) internal returns (uint) {
        bool found = false;
        uint start = parser.pos;
        byte c;
        for (; parser.pos < s.length; parser.pos++) {
            c = s[parser.pos];
            if (c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == ','
                || c == 0x7d || c == 0x5d) {
                    found = true;
                    break;
            }
            if (c < 32 || c > 127) {
                parser.pos = start;
                return RETURN_ERROR_INVALID_JSON;
            }
        }
        if (!found) {
            parser.pos = start;
            return RETURN_ERROR_PART;
        }

        // found the end
        var (success, token) = allocateToken(parser, tokens);
        if (!success) {
            parser.pos = start;
            return RETURN_ERROR_NO_MEM;
        }
        fillToken(token, JsmnType.PRIMITIVE, start, parser.pos);
        parser.pos--;
        return RETURN_SUCCESS;
    }

    function parse(string json, uint numberElements) internal returns (uint, Token[], uint) {
        bytes memory s = bytes(json);
        var (parser, tokens) = init(numberElements);

        // Token memory token;
        uint r;
        uint count = parser.toknext;
        uint i;

        for (; parser.pos<s.length; parser.pos++) {
            bytes1 c = s[parser.pos];

            // 0x7b, 0x5b opening curly parentheses or brackets
            if (c == 0x7b || c == 0x5b) {
                count++;
                var (success, token)= allocateToken(parser, tokens);
                if (!success) {
                    return (RETURN_ERROR_NO_MEM, tokens, 0);
                }
                if (parser.toksuper != -1) {
                    tokens[uint(parser.toksuper)].size++;
                }
                token.jsmnType = (c == 0x7b ? JsmnType.OBJECT : JsmnType.ARRAY);
                token.start = parser.pos;
                token.startSet = true;
                parser.toksuper = int(parser.toknext - 1);
                continue;
            }

            // closing curly parentheses or brackets
            if (c == 0x7d || c == 0x5d) {
                JsmnType tokenType = (c == 0x7d ? JsmnType.OBJECT : JsmnType.ARRAY);
                bool isUpdated = false;
                for (i=parser.toknext-1; i>=0; i--) {
                    token = tokens[i];
                    if (token.startSet && !token.endSet) {
                        if (token.jsmnType != tokenType) {
                            // found a token that hasn't been closed but from a different type
                            return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                        }
                        parser.toksuper = -1;
                        tokens[i].end = parser.pos + 1;
                        tokens[i].endSet = true;
                        isUpdated = true;
                        break;
                    }
                }
                if (!isUpdated) {
                    return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                }
                for (; i>0; i--) {
                    token = tokens[i];
                    if (token.startSet && !token.endSet) {
                        parser.toksuper = int(i);
                        break;
                    }
                }

                if (i==0) {
                    token = tokens[i];
                    if (token.startSet && !token.endSet) {
                        parser.toksuper = uint128(i);
                    }
                }
                continue;
            }

            // 0x42
            if (c == '"') {
                r = parseString(parser, tokens, s);

                if (r != RETURN_SUCCESS) {
                    return (r, tokens, 0);
                }
                //JsmnError.INVALID;
                count++;
				if (parser.toksuper != -1)
					tokens[uint(parser.toksuper)].size++;
                continue;
            }

            // ' ', \r, \t, \n
            if (c == ' ' || c == 0x11 || c == 0x12 || c == 0x14) {
                continue;
            }

            // 0x3a
            if (c == ':') {
                parser.toksuper = int(parser.toknext -1);
                continue;
            }

            if (c == ',') {
                if (parser.toksuper != -1
                    && tokens[uint(parser.toksuper)].jsmnType != JsmnType.ARRAY
                    && tokens[uint(parser.toksuper)].jsmnType != JsmnType.OBJECT) {
                        for(i = parser.toknext-1; i>=0; i--) {
                            if (tokens[i].jsmnType == JsmnType.ARRAY || tokens[i].jsmnType == JsmnType.OBJECT) {
                                if (tokens[i].startSet && !tokens[i].endSet) {
                                    parser.toksuper = int(i);
                                    break;
                                }
                            }
                        }
                    }
                continue;
            }

            // Primitive
            if ((c >= '0' && c <= '9') || c == '-' || c == 'f' || c == 't' || c == 'n') {
                if (parser.toksuper != -1) {
                    token = tokens[uint(parser.toksuper)];
                    if (token.jsmnType == JsmnType.OBJECT
                        || (token.jsmnType == JsmnType.STRING && token.size != 0)) {
                            return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                        }
                }

                r = parsePrimitive(parser, tokens, s);
                if (r != RETURN_SUCCESS) {
                    return (r, tokens, 0);
                }
                count++;
                if (parser.toksuper != -1) {
                    tokens[uint(parser.toksuper)].size++;
                }
                continue;
            }

            // printable char
            if (c >= 0x20 && c <= 0x7e) {
                return (RETURN_ERROR_INVALID_JSON, tokens, 0);
            }
        }

        return (RETURN_SUCCESS, tokens, parser.toknext);
    }

    function getBytes(string json, uint start, uint end) internal returns (string) {
        bytes memory s = bytes(json);
        bytes memory result = new bytes(end-start);
        for (uint i=start; i<end; i++) {
            result[i-start] = s[i];
        }
        return string(result);
    }

    // parseInt
    function parseInt(string _a) internal returns (int) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string _a, uint _b) internal returns (int) {
        bytes memory bresult = bytes(_a);
        int mint = 0;
        bool decimals = false;
        bool negative = false;
        for (uint i=0; i<bresult.length; i++){
            if ((i == 0) && (bresult[i] == '-')) {
                negative = true;
            }
            if ((bresult[i] >= 48) && (bresult[i] <= 57)) {
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += int(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= int(10**_b);
        if (negative) mint *= -1;
        return mint;
    }

    function uint2str(uint i) internal returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function parseBool(string _a) returns (bool) {
        if (strCompare(_a, 'true') == 0) {
            return true;
        } else {
            return false;
        }
    }

    function strCompare(string _a, string _b) internal returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
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

contract FootballBetting {
  /***********************************/
  /******* CONTRACT ATTRIBUTES *******/
  /***********************************/

  struct Bet {
    uint betID;
    address proposer;
    address acceptor;
    bool accepted;
    uint acceptorAmount;
    uint proposerAmount;
    uint proposerHomeScore;
    uint proposerAwayScore;
    bool resolved;
    int fixtureID;
    uint totalAmount;
    bool deleted;
  }

  address public master;
  uint betCount;
  uint[] betIDs;
  mapping(uint => Bet) public bets;

  /***********************************/
  /************* MODIFIERS ***********/
  /***********************************/


  /***********************************/
  /************** EVENTS *************/
  /***********************************/

  event BetChange(uint betID);
  /***********************************/
  /********* PUBLIC FUNCTIONS ********/
  /***********************************/

  /// @dev      Betting contract constructor sets initial bet count to 0
  function Betting() public {
    master = msg.sender;
    betCount = 0;
  }

  /// @dev                    Allows a user to propose a bet
  /// @param  _proof  The json file passing through from the football API
  /// @param  _acceptorAmount The odds put forward by the user
  /// @param  _home_score     The home score proposed by the user
  /// @param  _away_score     The away score proposed by the user
  function proposeBet(bytes memory _proof, uint _acceptorAmount, uint _home_score, uint _away_score) public payable {
    require(verifyProof(_proof));
    require(msg.value > 0);

    string memory json = string(tlsnutils.getHTTPBody(_proof));
    uint returnValue;
    JsmnSolLib.Token[] memory tokens;
    uint actualNum;
    (returnValue, tokens, actualNum) = JsmnSolLib.parse(json, 100);
    // Next check that the fixture being inputted has null scores (i.e. a fixture in the future)
    string memory score1 = JsmnSolLib.getBytes(json, tokens[25].start, tokens[25].end);
    string memory score2 = JsmnSolLib.getBytes(json, tokens[27].start, tokens[27].end);

    require(compareStrings(score1,'null') && compareStrings(score2, 'null'));

    string memory fixtureIDStr = JsmnSolLib.getBytes(json, tokens[5].start, tokens[5].end);
    int fixtureID = JsmnSolLib.parseInt(fixtureIDStr);
    uint betID = (betCount++)+1000;
    betIDs.push(betID);
    bets[betID] = Bet(betID, msg.sender, 0, false, _acceptorAmount, msg.value,_home_score,_away_score,false,fixtureID,(msg.value+_acceptorAmount), false);
    BetChange(betID);
  }

  /// @dev       Compares two strings
  /// @param  a  The first string to be compared
  /// @param  b  The second string to be compared
  /// @return    Returns true if two strings are the same, false otherwise
  function compareStrings (string a, string b) public returns (bool){
       return keccak256(a) == keccak256(b);
   }

   /// @dev            Allows a user to accept a proposed bet
   /// @param  _betID  The bet ID that the user is accepting
   /// @return         The second string to be compared

  function acceptBet(uint _betID) public payable {
    require((msg.value == (bets[_betID].acceptorAmount)) &&
      !bets[_betID].accepted && (msg.sender != bets[_betID].proposer));
      bets[_betID].acceptor = msg.sender;
      bets[_betID].accepted = true;
      BetChange(_betID);
  }

  /// @dev                    Calculates the winner of a specific bet
  /// @param  _betID          The bet ID that is being used
  /// @param  _proof  The json file with the fixture ID and results
  function resolveBet(uint _betID, bytes memory _proof) public payable {
    // First check that the json being passed in actually has scores for the match
    require(verifyProof(_proof));

    string memory json = string(tlsnutils.getHTTPBody(_proof));
    uint returnValue;
    JsmnSolLib.Token[] memory tokens;
    uint actualNum;
    (returnValue, tokens, actualNum) = JsmnSolLib.parse(json, 100);
    string memory score1 = JsmnSolLib.getBytes(json, tokens[25].start, tokens[25].end);
    string memory score2 = JsmnSolLib.getBytes(json, tokens[27].start, tokens[27].end);

    string memory fixtureIDStr = JsmnSolLib.getBytes(json, tokens[5].start, tokens[5].end);
    int fixtureID = JsmnSolLib.parseInt(fixtureIDStr);
    require(fixtureID == bets[_betID].fixtureID);

    require((!compareStrings(score1,'null') && !compareStrings(score2,'null')));
    int score1int = JsmnSolLib.parseInt(score1);
    int score2int = JsmnSolLib.parseInt(score2);
    bets[_betID].resolved = true;

    if (bets[_betID].proposerHomeScore == uint(score1int) && bets[_betID].proposerAwayScore == uint(score2int)) {
      bets[_betID].proposer.transfer(bets[_betID].totalAmount);
    }
    else {
      bets[_betID].acceptor.transfer(bets[_betID].totalAmount);
    }
  }

  /**
   * @dev            allows user to cancel a proposed bet, betID is deleted and
   *                 bet funds transfered to the proposer
   * @param _betID   The bet ID that is being canceled
   */
  function cancelBet(uint _betID) public payable {
      require(bets[_betID].proposer == msg.sender);
      require(bets[_betID].accepted == false);
      bets[_betID].deleted = true;
      BetChange(_betID);
      bets[_betID].proposer.transfer(bets[_betID].proposerAmount);
  }

  /// @dev                    Returns details of a bet
  /// @param  _betID          The bet ID that you are requesting
  /// @return                 1. odds of the bet, 2. bet amount, 3. proposer home score,
  ///                         4. proposer away score, 5. the fixture ID, 6. the proposer address
  ///                         7. a boolean stating whether the bet has finished or not
  function getBet(uint _betID) public constant returns (uint, uint, uint, uint, int, address, address) {
    return  ( bets[_betID].proposerAmount,
              bets[_betID].acceptorAmount,
              bets[_betID].proposerHomeScore,
              bets[_betID].proposerAwayScore,
              bets[_betID].fixtureID,
              bets[_betID].proposer,
	      bets[_betID].acceptor);
  }

  /// @dev                    Returns an array of all bet IDs
  /// @return                 All bet IDs that have ever been created
  function getBets() public constant returns (uint[]) {
    return betIDs;
  }

  /// @dev                    Allows the requestor to see how many bets have been created
  /// @return                 Returns an integer of the number of bets
  function getNumberOfBets() public constant returns (uint) {
   return betIDs.length;
  }

  /***********************************/
  /******** PRIVATE FUNCTIONS ********/
  /***********************************/

  function verifyProof(bytes memory proof) private returns (bool){
    uint256 qx = 0xe0a5793d275a533d50421b201c2c9a909abb58b1a9c0f9eb9b7963e5c8bc2295;
    uint256 qy = 0xf34d47cb92b6474562675127677d4e446418498884c101aeb38f3afb0cab997e;

    if(tlsnutils.verifyProof(proof, qx, qy)) {
      return true;
    }
    return false;
  }
}
