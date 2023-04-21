const path = require("path");

const chai = require("chai");
const assert = chai.assert;

const c_tester = require("circom_tester").c;

const utils = require("./utils");
const keccak256 = require("keccak256");
const wasm_tester = require("circom_tester/wasm/tester");

describe("Keccak 32bytes full hash test", function () {
    this.timeout(100000);

    let cir;
    before(async () => {
	cir = await c_tester(path.join(__dirname, "circuits", "keccak_256_256_test.circom"));
	await cir.loadConstraints();
	console.log("n_constraints", cir.constraints.length);
    });

    it ("Keccak 1 (testvector generated from go)", async () => {
	const input = [116, 101, 115, 116, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
	const expectedOut = [37, 17, 98, 135, 161, 178, 88, 97, 125, 150, 143,
	    65, 228, 211, 170, 133, 153, 9, 88, 212, 4, 212, 175, 238, 249,
	    210, 214, 116, 170, 85, 45, 21];

	const inIn = utils.bytesToBits(input);

	const witness = await cir.calculateWitness({ "in": inIn }, true);

	const stateOut = witness.slice(1, 1+(32*8));
	const stateOutBytes = utils.bitsToBytes(stateOut);
	// console.log(stateOutBytes, expectedOut);
	assert.deepEqual(stateOutBytes, expectedOut);
    });
    it ("Keccak 2 (testvector generated from go)", async () => {
	const input = [37, 17, 98, 135, 161, 178, 88, 97, 125, 150, 143, 65,
	    228, 211, 170, 133, 153, 9, 88, 212, 4, 212, 175, 238, 249, 210,
	    214, 116, 170, 85, 45, 21];
	const expectedOut = [182, 104, 121, 2, 8, 48, 224, 11, 238, 244, 73,
	    142, 67, 205, 166, 27, 10, 223, 142, 209, 10, 46, 171, 110, 239,
	    68, 111, 116, 164, 127, 103, 141];

	const inIn = utils.bytesToBits(input);

	const witness = await cir.calculateWitness({ "in": inIn }, true);

	const stateOut = witness.slice(1, 1+(32*8));
	const stateOutBytes = utils.bitsToBytes(stateOut);
	// console.log(stateOutBytes, expectedOut);
	assert.deepEqual(stateOutBytes, expectedOut);
    });
    it ("Keccak 3 (testvector generated from go)", async () => {
	const input = [182, 104, 121, 2, 8, 48, 224, 11, 238, 244, 73, 142, 67,
	    205, 166, 27, 10, 223, 142, 209, 10, 46, 171, 110, 239, 68, 111,
	    116, 164, 127, 103, 141];
	const expectedOut = [191, 235, 249, 254, 70, 24, 106, 244, 212, 163,
	    52, 240, 1, 128, 235, 61, 158, 52, 138, 60, 197, 80, 113, 36, 44,
	    217, 55, 211, 97, 231, 26, 7];

	const inIn = utils.bytesToBits(input);

	const witness = await cir.calculateWitness({ "in": inIn }, true);

	const stateOut = witness.slice(1, 1+(32*8));
	const stateOutBytes = utils.bitsToBytes(stateOut);
	// console.log(stateOutBytes, expectedOut);
	assert.deepEqual(stateOutBytes, expectedOut);
    });
    it ("Keccak 4 (testvector generated from go)", async () => {
	const input = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
	const expectedOut = [41, 13, 236, 217, 84, 139, 98, 168, 214, 3, 69,
	    169, 136, 56, 111, 200, 75, 166, 188, 149, 72, 64, 8, 246, 54, 47,
	    147, 22, 14, 243, 229, 99];

	const inIn = utils.bytesToBits(input);

	const witness = await cir.calculateWitness({ "in": inIn }, true);

	const stateOut = witness.slice(1, 1+(32*8));
	const stateOutBytes = utils.bitsToBytes(stateOut);
	// console.log(stateOutBytes, expectedOut);
	assert.deepEqual(stateOutBytes, expectedOut);
    });

    describe("Keccak256 circuit check with js version", function () {
	this.timeout(100000);

	it ("Keccak256 circom-js 1", async () => {
	    let input, inputBits, expectedOut, witness, stateOut, stateOutBytes;
	    input = Buffer.from("0000000000000000000000000000000000000000000000000000000000000000", "hex");
	    for(let i=0; i<10; i++) {
		inputBits = utils.bytesToBits(input);

		let jsOutRaw = keccak256(input);
		expectedOut = utils.bufferToBytes(jsOutRaw);
		console.log(i, "in:", input.toString('hex'), "\n out:", jsOutRaw.toString('hex'));

		witness = await cir.calculateWitness({ "in": inputBits }, true);
		stateOut = witness.slice(1, 1+(32*8));
		stateOutBytes = utils.bitsToBytes(stateOut);
		assert.deepEqual(stateOutBytes, expectedOut);

		// assign output into input for next iteration
		input = jsOutRaw;
	    }
	});
    });
});

describe("Keccak input: 4bytes, output: 32bytes, full hash test", function () {
    this.timeout(100000);

    let cir;
    before(async () => {
	cir = await c_tester(path.join(__dirname, "circuits", "keccak_32_256_test.circom"));
	await cir.loadConstraints();
	console.log("n_constraints", cir.constraints.length);
    });

    it ("Keccak inputSize==32bits: 1 (testvector generated from go)", async () => {
	const input = [116, 101, 115, 116];
	const expectedOut = [156, 34, 255, 95, 33, 240, 184, 27, 17, 62, 99,
	    247, 219, 109, 169, 79, 237, 239, 17, 178, 17, 155, 64, 136, 184,
	    150, 100, 251, 154, 60, 182, 88];

	const inIn = utils.bytesToBits(input);

	const witness = await cir.calculateWitness({ "in": inIn }, true);

	const stateOut = witness.slice(1, 1+(32*8));
	const stateOutBytes = utils.bitsToBytes(stateOut);
	// console.log(stateOutBytes, expectedOut);
	assert.deepEqual(stateOutBytes, expectedOut);
    });

    it ("Keccak256 inputSize==32bits, circom-js 1", async () => {
	let input, inputBits, expectedOut, witness, stateOut, stateOutBytes;
	input = Buffer.from("test");
	for(let i=0; i<10; i++) {
	    inputBits = utils.bytesToBits(input);

	    let jsOutRaw = keccak256(input);
	    expectedOut = utils.bufferToBytes(jsOutRaw);
	    console.log(i, "in:", input.toString('hex'), "\n out:", jsOutRaw.toString('hex'));

	    witness = await cir.calculateWitness({ "in": inputBits }, true);
	    stateOut = witness.slice(1, 1+(32*8));
	    stateOutBytes = utils.bitsToBytes(stateOut);
	    assert.deepEqual(stateOutBytes, expectedOut);

	    // assign output[0:4] into input for next iteration
	    input = jsOutRaw.slice(0, 4);
	}
    });
});

describe("KeccakV 3000bits test", function () {
    this.timeout(100000);

	function padInputBits(inputBits) {
		var inputLen = inputBits.length;
		for (var i = 0; i < 3000-inputLen; i++) {
			inputBits.push(i%2);
		}
		return inputBits;
	}

    let cir;
    before(async () => {
	cir = await wasm_tester(path.join(__dirname, "circuits", "keccak_3000V_256_test.circom"));
	await cir.loadConstraints();
	console.log("n_constraints", cir.constraints.length);
    });

    it ("KeccakV 32-bytes 1 (testvector generated from go)", async () => {
	const input = [116, 101, 115, 116, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
	const expectedOut = [37, 17, 98, 135, 161, 178, 88, 97, 125, 150, 143,
	    65, 228, 211, 170, 133, 153, 9, 88, 212, 4, 212, 175, 238, 249,
	    210, 214, 116, 170, 85, 45, 21];
	const len = input.length*8;

	const inIn = utils.bytesToBits(input);

	const witness = await cir.calculateWitness({ "in": padInputBits(inIn), "len": len }, true);

	const stateOut = witness.slice(1, 1+(32*8));
	const stateOutBytes = utils.bitsToBytes(stateOut);
	// console.log(stateOutBytes, expectedOut);
	assert.deepEqual(stateOutBytes, expectedOut);
    });

    it ("KeccakV 256 bytes (testvector generated from go)", async () => {
	const input = [37, 17, 98, 135, 161, 178, 88, 97, 125, 150, 143, 65,
	    228, 211, 170, 133, 153, 9, 88, 212, 4, 212, 175, 238, 249, 210,
	    214, 116, 170, 85, 45, 21];
	const expectedOut = [182, 104, 121, 2, 8, 48, 224, 11, 238, 244, 73,
	    142, 67, 205, 166, 27, 10, 223, 142, 209, 10, 46, 171, 110, 239,
	    68, 111, 116, 164, 127, 103, 141];
	const len = input.length*8;

	const inIn = utils.bytesToBits(input);

	const witness = await cir.calculateWitness({ "in": padInputBits(inIn), "len": len }, true);

	const stateOut = witness.slice(1, 1+(32*8));
	const stateOutBytes = utils.bitsToBytes(stateOut);
	// console.log(stateOutBytes, expectedOut);
	assert.deepEqual(stateOutBytes, expectedOut);
    });
});

describe("KeccakV bsc_header test", function () {
    this.timeout(10000000);

	function padInputBits(inputBits) {
		var inputLen = inputBits.length;
		for (var i = 0; i < 1075*8-inputLen; i++) {
			inputBits.push(i%2);
		}
		return inputBits;
	}

    let cir;
    before(async () => {
	cir = await wasm_tester(path.join(__dirname, "circuits", "keccak_bsc_header_test.circom"));
	await cir.loadConstraints();
	console.log("n_constraints", cir.constraints.length);
    });

    it ("KeccakV bsc header 1 (testvector generated from go)", async () => {
	const input = [249, 3, 195, 56, 160, 137, 140, 146, 110, 64, 68, 9, 214, 21, 29, 14, 14, 161, 86, 119, 15, 218, 162, 179, 31, 129, 21, 181, 242, 11, 203, 27, 108, 180, 220, 52, 195, 160, 29, 204, 77, 232, 222, 199, 93, 122, 171, 133, 181, 103, 182, 204, 212, 26, 211, 18, 69, 27, 148, 138, 116, 19, 240, 161, 66, 253, 64, 212, 147, 71, 148, 114, 182, 28, 96, 20, 52, 45, 145, 68, 112, 236, 122, 194, 151, 91, 227, 69, 121, 108, 43, 160, 93, 3, 166, 106, 231, 253, 204, 107, 255, 81, 228, 192, 207, 64, 198, 236, 45, 41, 16, 144, 189, 221, 144, 115, 202, 66, 3, 216, 75, 9, 155, 185, 160, 179, 219, 102, 188, 73, 234, 201, 19, 219, 219, 232, 174, 170, 238, 137, 23, 98, 166, 197, 194, 137, 144, 195, 245, 241, 97, 114, 106, 140, 177, 196, 29, 160, 4, 174, 168, 243, 210, 71, 27, 122, 230, 75, 206, 93, 222, 123, 184, 234, 250, 76, 247, 60, 101, 234, 181, 204, 4, 159, 146, 179, 253, 166, 93, 204, 185, 1, 0, 79, 122, 70, 110, 189, 137, 214, 114, 233, 215, 51, 120, 208, 59, 133, 32, 71, 32, 231, 94, 159, 159, 174, 32, 177, 74, 108, 95, 175, 28, 165, 248, 221, 80, 213, 177, 7, 112, 54, 225, 89, 110, 242, 40, 96, 220, 163, 34, 221, 210, 140, 193, 139, 230, 177, 99, 142, 91, 189, 221, 118, 37, 27, 222, 87, 252, 157, 6, 167, 66, 27, 91, 93, 13, 136, 188, 185, 185, 32, 173, 238, 211, 219, 176, 159, 213, 91, 22, 173, 213, 245, 136, 222, 182, 188, 246, 75, 189, 89, 191, 171, 75, 130, 81, 122, 28, 143, 195, 66, 35, 59, 161, 122, 57, 74, 109, 197, 175, 191, 208, 172, 252, 68, 58, 68, 114, 33, 38, 64, 207, 41, 79, 155, 216, 100, 164, 172, 133, 70, 94, 218, 234, 120, 154, 0, 126, 127, 23, 194, 49, 196, 174, 121, 14, 44, 237, 98, 234, 239, 16, 131, 92, 72, 100, 199, 229, 182, 74, 217, 245, 17, 222, 247, 58, 7, 98, 69, 6, 89, 130, 95, 96, 206, 180, 140, 158, 136, 182, 231, 117, 132, 129, 106, 46, 181, 127, 218, 186, 84, 183, 29, 120, 92, 139, 133, 222, 51, 134, 229, 68, 204, 242, 19, 236, 220, 148, 46, 240, 25, 58, 250, 233, 236, 238, 147, 255, 4, 255, 144, 22, 224, 106, 3, 57, 61, 77, 138, 225, 74, 37, 12, 157, 215, 27, 240, 159, 238, 109, 226, 110, 84, 244, 5, 217, 71, 225, 2, 131, 117, 149, 144, 132, 3, 145, 161, 127, 132, 1, 81, 167, 178, 132, 96, 172, 115, 143, 185, 1, 196, 216, 131, 1, 1, 0, 132, 103, 101, 116, 104, 136, 103, 111, 49, 46, 49, 53, 46, 53, 133, 108, 105, 110, 117, 120, 0, 0, 0, 252, 60, 166, 183, 36, 101, 23, 108, 70, 26, 251, 49, 110, 188, 119, 60, 97, 250, 238, 133, 166, 81, 93, 170, 41, 94, 38, 73, 92, 239, 111, 105, 223, 166, 153, 17, 217, 216, 228, 243, 187, 173, 184, 155, 41, 169, 124, 110, 255, 184, 164, 17, 218, 188, 106, 222, 239, 170, 132, 245, 6, 124, 139, 190, 45, 76, 64, 123, 190, 73, 67, 142, 216, 89, 254, 150, 91, 20, 13, 207, 26, 171, 113, 169, 63, 52, 155, 186, 254, 193, 85, 24, 25, 184, 190, 30, 254, 162, 252, 70, 202, 116, 154, 161, 68, 48, 179, 35, 2, 148, 209, 44, 106, 178, 170, 197, 194, 205, 104, 232, 11, 22, 181, 129, 104, 91, 29, 237, 128, 19, 120, 93, 102, 35, 204, 24, 210, 20, 50, 11, 107, 182, 71, 89, 112, 246, 87, 22, 78, 91, 117, 104, 155, 100, 183, 253, 31, 162, 117, 243, 52, 242, 142, 24, 114, 182, 28, 96, 20, 52, 45, 145, 68, 112, 236, 122, 194, 151, 91, 227, 69, 121, 108, 43, 122, 226, 245, 185, 227, 134, 205, 27, 80, 164, 85, 6, 150, 217, 87, 203, 73, 0, 240, 58, 139, 108, 143, 217, 61, 111, 76, 234, 66, 187, 179, 69, 219, 198, 240, 223, 219, 91, 236, 115, 155, 184, 50, 37, 75, 175, 78, 139, 76, 194, 107, 210, 181, 43, 49, 56, 155, 86, 233, 139, 159, 140, 205, 175, 204, 57, 243, 199, 214, 235, 246, 55, 201, 21, 22, 115, 203, 195, 107, 136, 166, 247, 155, 96, 53, 159, 20, 29, 249, 10, 12, 116, 81, 37, 177, 49, 202, 175, 253, 18, 184, 247, 22, 100, 150, 153, 106, 125, 162, 28, 241, 241, 176, 77, 155, 62, 38, 163, 208, 119, 190, 128, 125, 221, 176, 116, 99, 156, 217, 250, 97, 180, 118, 118, 192, 100, 252, 80, 214, 44, 206, 47, 215, 84, 78, 11, 44, 201, 70, 146, 212, 167, 4, 222, 190, 247, 188, 182, 19, 40, 226, 211, 167, 57, 239, 252, 211, 169, 147, 135, 208, 21, 226, 96, 238, 250, 199, 46, 190, 161, 233, 174, 50, 97, 164, 117, 162, 123, 177, 2, 143, 20, 11, 194, 167, 200, 67, 49, 138, 253, 234, 10, 110, 60, 81, 27, 189, 16, 244, 81, 158, 206, 55, 220, 36, 136, 126, 17, 181, 93, 238, 34, 99, 121, 219, 131, 207, 252, 104, 20, 149, 115, 12, 17, 253, 222, 121, 186, 76, 12, 160, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 136, 0, 0, 0, 0, 0, 0, 0, 0];
	const expectedOut = [47, 23, 206, 197, 127, 147, 238, 27, 221, 135, 239, 15, 62, 207, 115, 45, 64, 214, 88, 58, 211, 217, 210, 67, 86, 155, 32, 59, 221, 249, 83, 123];
	const len = input.length*8;

	const inIn = utils.bytesToBits(input);

	const witness = await cir.calculateWitness({ "in": padInputBits(inIn), "len": len }, true);

	const stateOut = witness.slice(1, 1+(32*8));
	const stateOutBytes = utils.bitsToBytes(stateOut);
	// console.log(stateOutBytes, expectedOut);
	assert.deepEqual(stateOutBytes, expectedOut);
    });
})

