class Application {

	/**
	 * Initialize the application, add event listeners and load the example image
	 */
	init(){
		// add a file input handler to load images
		document.getElementById("img_input").addEventListener("change", (e) => {
			const file = e.target.files[0];
			const reader = new FileReader();
			reader.onload = (e) => {
				const img = new Image();
				img.src = e.target.result;
				img.onload = () => {
					this.displayImg(img);
				};
			};
			reader.readAsDataURL(file);
		});

		// add event listeners to the save buttons
		document.getElementById("bmp_btn").addEventListener("click", () => {
			this.saveImg("bmp");
		});
		document.getElementById("pcx_btn").addEventListener("click", () => {
			this.saveImg("pcx");
		});

		// load the example image
		(() => {
			const img = new Image();
			img.src = "./example.jpg";
			img.onload = () => { this.displayImg(img); };
		})();
	}

	/**
	 * Draw the given Image object on the canvas
	 */
	displayImg(img){
		const canvas = document.getElementById("img_canvas");
		const ctx = canvas.getContext("2d");
		canvas.width = img.width;
		canvas.height = img.height;
		ctx.drawImage(img, 0, 0);
	}

	/**
	 * Saves the current cansvas image as a BMP or PCX file. Type must be either "bmp" or "pcx"
	 */
	saveImg(type){
		const canvas = document.getElementById("img_canvas");
		const width = canvas.width;
		const height = canvas.height;
		if(!width || !height){
			throw new Error("No image loaded");
		}

		const ctx = canvas.getContext("2d");
		const imgData = ctx.getImageData(0, 0, width, height);
		const data = [];
		for(let i=0; i<imgData.data.length; i+=4){
			const r = imgData.data[i];
			const g = imgData.data[i+1];
			const b = imgData.data[i+2];
			const a = imgData.data[i+3];
			const gray = Math.round(0.299*r + 0.587*g + 0.114*b);
			const bin = gray > 128 ? 1 : 0;
			data.push(bin);
		}

		switch(type){
			case "bmp":
				this.saveAsBmp({ width, height, data });
				break;
			case "pcx":
				this.saveAsPcx({ width, height, data });
				break;
			default:
				throw new Error(`Invalid image type: ${type}`);
		}
	}

	/**
	 * Converts the given big-endian hex string to little-endian. The hex string must represent an integer number of bytes
	 */
	convertToLittleEndian(hexStr){
		if(hexStr.length % 2 !== 0){
			throw new Error("Invalid hex string length");
		}
		// split the hex string into bytes
		const hexArr = hexStr.match(/.{2}/g);
		// reverse the byte ordering then join and return
		return hexArr.reverse().join("");
	}

	/**
	 * converts the given binary string to a hex string. The binary string must represent and integer number of bytes
	 * conversion is done one byte at a time and then joined together
	 */
	binaryToHex(binStr){
		const binLen = binStr.length;
		if(binLen % 8 !== 0){
			throw new Error("Invalid binary string length");
		}
		// split the binary string into bytes
		const binArr = binStr.match(/.{8}/g);
		// convert each byte to int and then to hex and pad with 0 if needed
		const hexArr = binArr.map(bin => parseInt(bin, 2).toString(16).padStart(2, "0"));
		return hexArr.join("");
	}

	/**
	 * RLE compress a hex string, used the specs from https://moddingwiki.shikadi.net/wiki/PCX_Format
	 * there are probably some bugs in here but it works for the example image
	 */
	rleCompress(hexStr){
		if(hexStr.length % 2 !== 0){
			throw new Error("Invalid hex string length");
		}

		// split the hex string into bytes
		const hexArr = hexStr.match(/.{2}/g);
		const hexLen = hexArr.length;
		let compressed = [];
		let count = 1;
		for(let i=0; i < hexLen; i++){
			if(i < hexLen - 1 && hexArr[i] === hexArr[i+1] && count < 63){
				// we are going to the same byte and have not reached the limit or the end
				count++;
			} else if(count > 1 || parseInt(hexArr[i], 16) >= 192){
				// we have a repeat, or the byte is 192 or greater so needs to be repeat encoded
				compressed.push((count + 192).toString(16).padStart(2, "0")); // the flag and count
				compressed.push(hexArr[i]); // the repeated byte
				count = 1;
			} else {
				// no repeat, just add the byte
				compressed.push(hexArr[i]);
			}
		}
		return compressed.join("");
	}

	/**
	 * I am fairly confident that this function is correct, but there are some nuances to BMP that I may have missed
	 * I have tested it with a few images and it seems to work fine
	 * Followed the specs from https://en.wikipedia.org/wiki/BMP_file_format
	 */
	saveAsBmp({ width, height, data }){
		const rowSize = Math.ceil(width / 32) * 4;
		const pixelSize = rowSize * height;
		const bmpHeaderSize = 14; // always 14
		const dibHeaderSize = 40; // always 40
		const colorTableSize = 2 * 4; // monochromatic has only 2 colors
		const minDataOffset = bmpHeaderSize + dibHeaderSize + colorTableSize; // where data would normally start
		const dataOffset = 4 * Math.ceil(minDataOffset / 4); // must be multiple of 4 so add some padding if needed
		const bmpSize = dataOffset + pixelSize; // total size of the file
	
		const hexData = [
			// Bitmap file header
			"424d", // BM, fixed file type identifier
			this.convertToLittleEndian(bmpSize.toString(16).padStart(8, "0")), // file size in bytes
			"".padStart(8, "0"), // reserved, application dependent, can be 0
			this.convertToLittleEndian(dataOffset.toString(16).padStart(8, "0")), // offset where data starts, must be multiple of 4
	
			// DIB header of type BITMAPINFOHEADER
			this.convertToLittleEndian(dibHeaderSize.toString(16).padStart(8, "0")), // size of DIB header, must be 40 for BITMAPINFOHEADER
			this.convertToLittleEndian(width.toString(16).padStart(8, "0")), // width of the image
			this.convertToLittleEndian(height.toString(16).padStart(8, "0")), // height of the image
			this.convertToLittleEndian((1).toString(16).padStart(4, "0")), // color plane, must be 1 for our ourposes
			this.convertToLittleEndian((1).toString(16).padStart(4, "0")), // bits per pixel, 1 for monochrome
			"".padStart(8, "0"), // compression, none
			"".padStart(8, "0"), // dummy because no compression
			this.convertToLittleEndian((1000).toString(16).padStart(8, "0")), // pixels per meter, horizontal, unimportant
			this.convertToLittleEndian((1000).toString(16).padStart(8, "0")), // pixels per meter, vertical, unimportant
			"".padStart(8, "0"), // colors in palette, 0 for 2^n
			"".toString(16).padStart(8, "0"), // important colors, 0 for all
	
			// Color table, only 2 colors for monochrome, probably unnecessary
			this.convertToLittleEndian("ff000000"), // color 0, black
			this.convertToLittleEndian("ffffffff"), // color 1, white
	
			// extra padding to reach the data offset before raster data
			"".padStart((dataOffset - minDataOffset) * 2, "0")
		];
	
		// add the raster data, we need to go from bottom to top
		for(let i=height - 1; i >= 0; i--){
			const rowData = [];
			for(let j=0; j<width; j++){
				rowData.push(data[i*width + j]);
			}
			// pad each row to the nearest multiple of 4 bytes
			const rowStr = rowData.join("").padEnd(rowSize * 8, "0");
			hexData.push(this.binaryToHex(rowStr));
		}
	
		const hexStr = hexData.join("");
		this.saveHexToFile(hexStr, "output.bmp", "image/bmp");
	}

	/**
	 * This function is probably not fully correct, but there isn't a lot of documentation on PCX and i did find best.
	 * I have tested it with a few images and it seems to work fine but there may be some edge cases that I missed.
	 * The main problem may be with the color palette or the RLE compression. I omitted the color palette for now,
	 * which should be fine for monochrome images. But when opening the PCX file with GIMP it asked me to choose a palette,
	 * and I just chose the black and white palette and everything displayed correctly.
	 */
	saveAsPcx({ width, height, data }){
		// each raster row must contain an even number of bytes
		let bytesPerLine = Math.ceil(width / 8);
		if(bytesPerLine % 2 !== 0){
			bytesPerLine++;
		}

		// PCX header is 128 bytes, we will use version 0 (which is paletteless), RLE encoding (which is mandatory?),
		// and 1 bit per pixel for monochorome
		const hexData = [
			"0a", // fixed manufacturer identifier
			(0).toString(16).padStart(2, "0"), // version, 0 for oldest, simplest, and paletteless
			(1).toString(16).padStart(2, "0"), // encoding, 1 for RLE. can be 0 for no compression but sources says it's not supported by most software
			(1).toString(16).padStart(2, "0"), // 1 bit per pixel
			"".padStart(4, "0"), // x min, 0, i can't think of any reason why this would ever be non-zero
			"".toString(16).padStart(4, "0"), // y min, 0
			this.convertToLittleEndian((width - 1).toString(16).padStart(4, "0")), // x max, must be width - 1 if x min is 0
			this.convertToLittleEndian((height - 1).toString(16).padStart(4, "0")), // y max
			this.convertToLittleEndian((300).toString(16).padStart(4, "0")), // horizontal DPI, probably unimportant
			this.convertToLittleEndian((300).toString(16).padStart(4, "0")), // vertical DPI, probably unimportant
			"".padEnd(48 * 2, "0"), // color palette, unused for version 0, i couldn't find a good source for how to define this
			"".padStart(2, "0"), // reserved, should be 0
			(1).toString(16).padStart(2, "0"), // number of color planes
			this.convertToLittleEndian(bytesPerLine.toString(16).padStart(4, "0")), // bytes per line, must be even
			this.convertToLittleEndian((1).toString(16).padStart(4, "0")), // palette info, 1 means color/bw. we have no palette but it works i guess
			this.convertToLittleEndian((1000).toString(16).padStart(4, "0")), // horizontal screen size of the software creating the image? who cares? probably unimportant
			this.convertToLittleEndian((1000).toString(16).padStart(4, "0")), // vertical screen size, same as above
			"".padEnd(54 * 2, "0") // padding to reach 128 bytes, can be junk
		];
	
		// each row of the image must be RLE encoded independenty
		// rows go top to bottom, unlike bmp
		for(let i=0; i < height; i++){
			const rowData = [];
			for(let j=0; j<width; j++){
				rowData.push(data[i*width + j]);
			}
			// get the uncompressed row hex string
			const rowStr = rowData.join("").padEnd(bytesPerLine * 8, "0");
			const rowHex = this.binaryToHex(rowStr);
			// RLE compress the row
			const rowHexRle = this.rleCompress(rowHex);
			hexData.push(rowHexRle);
		}
	
		const hexStr = hexData.join("");
		this.saveHexToFile(hexStr, "output.pcx", "image/x-pcx");
	}

	/**
	 * I just wrote the function name and copilot did the rest, probably correct
	 */
	saveHexToFile(hexString, filename, mimeType) {
		const byteCharacters = hexString.match(/.{1,2}/g).map(byte => parseInt(byte, 16));
		const byteArray = new Uint8Array(byteCharacters);
		const blob = new Blob([byteArray], { type: mimeType });
		const url = URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = filename;
		document.body.appendChild(a);
		a.click();
		document.body.removeChild(a);
		URL.revokeObjectURL(url);
	}

};

// the entry point of the application
const main = () => {
	const app = new Application();
	app.init();
};

window.onload = main;