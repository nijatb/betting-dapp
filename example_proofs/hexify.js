
//var fs = require("fs");
//var text = fs.readFileSync("./test.proof");
//console.log(text)
//var hex = buff2Hex(text)
//console.log(hex)

// Hex string
var a = "\x41"
console.log(a) // Printing hex string

// Decimal array with [65] (41 in hex)
var arr = new Uint8Array([65])
var str = buff2Hex(arr) // Convert to hex string
console.log(str) // Print hex string

function buff2Hex(buffer) {
    // buffer is an ArrayBuffer
    // create a byte array (Uint8Array) that we can read the array buffer
    const byteArray = new Uint8Array(buffer);
    // for each element, we want to get itsa two-digit hexadecimal representation
    const hexParts = [];
    for(let i = 0; i < byteArray.length; i++) {
	// convert value to hexadecimal
	const hex = byteArray[i].toString(16);
	
	// pad with zeros to length 2
	// and add \x in front of every hex
	const paddedHex = ('\\x') + ('00' + hex).slice(-2);
	
	// push to array
	hexParts.push(paddedHex);
    }
    // join all the hex values of the elements into a single string
    //console.log(hexParts)
    var hexStr = hexParts.join('');
    return hexStr;
}
