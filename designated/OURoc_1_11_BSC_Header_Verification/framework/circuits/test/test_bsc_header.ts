import { ethers } from "ethers";
import RLP from 'rlp';
import path from "path";
import { expect, assert } from 'chai';
const circom_tester = require('circom_tester');
const wasm_tester = circom_tester.wasm;

function hexStringToBigIntArray(hexString: string, len: number) {
    const hexNum = hexString.length / len;
    const result = [];
    for (let i = 0; i < len; i++) {
        const hex = hexString.substring(i * hexNum, i * hexNum + hexNum);
        result.push(BigInt("0x" + hex));
    }
    return result.reverse();
}

function hexStringToUint8Array(hexString: string) {
    if (hexString.length % 2 !== 0) {
        throw new Error("Invalid hex string length");
    }

    const byteArray = new Uint8Array(hexString.length / 2);
    for (let i = 0; i < hexString.length; i += 2) {
        const byte = parseInt(hexString.substring(i, 2), 16);
        if (isNaN(byte)) {
            throw new Error(`Invalid hex character at position ${i}`);
        }
        byteArray[i / 2] = byte;
    }
    return byteArray;
}

// Function to convert hex string to a number array
function hexStringToUInt4Array(hexString: string) {
    const numberArray = new Array(hexString.length);
    for (let i = 0; i < hexString.length; i++) {
        const byte = parseInt(hexString[i], 16);
        if (isNaN(byte)) {
            throw new Error(`Invalid hex character at position ${i}`);
        }
        numberArray[i] = byte;
    }
    return numberArray;
}

function uint8ArrayToHexString(uint8Array: any) {
    let hexString = "";
    for (let i = 0; i < uint8Array.length; i++) {
        const hex = uint8Array[i].toString(16);
        hexString += hex.length === 1 ? "0" + hex : hex;
    }
    return hexString;
}

function uint4ArrayToHexString(uint4Array: any) {
    let hexString = "";
    for (let i = 0; i < uint4Array.length; i++) {
        const hex = uint4Array[i].toString(16);
        hexString += hex;
    }
    return hexString;
}

function uint64ArrayToHexString(uint64Array: any) {
    let s = 0n;
    for (let i = 0; i < 4; i++) {
        s += uint64Array[i] * (1n << (64n * BigInt(i)));
        // s += uint64Array[i] * (1n << (64n * (3n - BigInt(i))));
    }
    const h = s.toString(16);
    return "0".repeat(64 - h.length) + h;
}

const headers = [
    // https://bscscan.com/block/7706000
    {
        difficulty: 0x2,
        // extra_data: '0xd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b72465176c461afb316ebc773c61faee85a6515daa295e26495cef6f69dfa69911d9d8e4f3bbadb89b29a97c6effb8a411dabc6adeefaa84f5067c8bbe2d4c407bbe49438ed859fe965b140dcf1aab71a93f349bbafec1551819b8be1efea2fc46ca749aa14430b3230294d12c6ab2aac5c2cd68e80b16b581685b1ded8013785d6623cc18d214320b6bb6475970f657164e5b75689b64b7fd1fa275f334f28e1872b61c6014342d914470ec7ac2975be345796c2b7ae2f5b9e386cd1b50a4550696d957cb4900f03a8b6c8fd93d6f4cea42bbb345dbc6f0dfdb5bec739bb832254baf4e8b4cc26bd2b52b31389b56e98b9f8ccdafcc39f3c7d6ebf637c9151673cbc36b88a6f79b60359f141df90a0c745125b131caaffd12b8f7166496996a7da21cf1f1b04d9b3e26a3d077be807dddb074639cd9fa61b47676c064fc50d62cce2fd7544e0b2cc94692d4a704debef7bcb61328e2d3a739effcd3a99387d015e260eefac72ebea1e9ae3261a475a27bb1028f140bc2a7c843318afdea0a6e3c511bbd10f4519ece37dc24887e11b55dee226379db83cffc681495730c11fdde79ba4c0c675b589d9452d45327429ff925359ca25b1cc0245ffb869dbbcffb5a0d3c72f103a1dcb28b105926c636747dbc265f8dda0090784be3febffdd7909aa6f416d200',
        extra_data: '0xd883010100846765746888676f312e31352e35856c696e7578000000fc3ca6b72465176c461afb316ebc773c61faee85a6515daa295e26495cef6f69dfa69911d9d8e4f3bbadb89b29a97c6effb8a411dabc6adeefaa84f5067c8bbe2d4c407bbe49438ed859fe965b140dcf1aab71a93f349bbafec1551819b8be1efea2fc46ca749aa14430b3230294d12c6ab2aac5c2cd68e80b16b581685b1ded8013785d6623cc18d214320b6bb6475970f657164e5b75689b64b7fd1fa275f334f28e1872b61c6014342d914470ec7ac2975be345796c2b7ae2f5b9e386cd1b50a4550696d957cb4900f03a8b6c8fd93d6f4cea42bbb345dbc6f0dfdb5bec739bb832254baf4e8b4cc26bd2b52b31389b56e98b9f8ccdafcc39f3c7d6ebf637c9151673cbc36b88a6f79b60359f141df90a0c745125b131caaffd12b8f7166496996a7da21cf1f1b04d9b3e26a3d077be807dddb074639cd9fa61b47676c064fc50d62cce2fd7544e0b2cc94692d4a704debef7bcb61328e2d3a739effcd3a99387d015e260eefac72ebea1e9ae3261a475a27bb1028f140bc2a7c843318afdea0a6e3c511bbd10f4519ece37dc24887e11b55dee226379db83cffc681495730c11fdde79ba4c0c0670403d7dfc4c816a313885fe04b850f96f27b2e9fd88b147c882ad7caf9b964abfe6543625fcca73b56fe29d3046831574b0681d52bf5383d6f2187b6276c100',
        gas_limit: 0x391a17f,
        gas_used: 0x151a7b2,
        log_bloom: '0x4f7a466ebd89d672e9d73378d03b85204720e75e9f9fae20b14a6c5faf1ca5f8dd50d5b1077036e1596ef22860dca322ddd28cc18be6b1638e5bbddd76251bde57fc9d06a7421b5b5d0d88bcb9b920adeed3dbb09fd55b16add5f588deb6bcf64bbd59bfab4b82517a1c8fc342233ba17a394a6dc5afbfd0acfc443a4472212640cf294f9bd864a4ac85465edaea789a007e7f17c231c4ae790e2ced62eaef10835c4864c7e5b64ad9f511def73a0762450659825f60ceb48c9e88b6e77584816a2eb57fdaba54b71d785c8b85de3386e544ccf213ecdc942ef0193afae9ecee93ff04ff9016e06a03393d4d8ae14a250c9dd71bf09fee6de26e54f405d947e1',
        coinbase: '0x72b61c6014342d914470eC7aC2975bE345796c2b',
        mix_digest: '0x0000000000000000000000000000000000000000000000000000000000000000',
        nonce: '0x0000000000000000',
        number: 0x759590,
        msg_hash: '0x2f17cec57f93ee1bdd87ef0f3ecf732d40d6583ad3d9d243569b203bddf9537b',
        parent_hash: '0x898c926e404409d6151d0e0ea156770fdaa2b31f8115b5f20bcb1b6cb4dc34c3',
        receipts_root: '0x04aea8f3d2471b7ae64bce5dde7bb8eafa4cf73c65eab5cc049f92b3fda65dcc',
        uncle_hash: '0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347',
        state_root: '0x5d03a66ae7fdcc6bff51e4c0cf40c6ec2d291090bddd9073ca4203d84b099bb9',
        timestamp: 0x60ac738f,
        transactions_root: '0xb3db66bc49eac913dbdbe8aeaaee891762a6c5c28990c3f5f161726a8cb1c41d'
    }
];

function get_bsc_message_rlp(header: any, chainId: number): [Uint8Array, string] {
    let list: any[] = [];

    list.push(chainId);
    list.push(ethers.utils.solidityPack(['bytes32'], [header.parent_hash]));
    list.push(ethers.utils.solidityPack(['bytes32'], [header.uncle_hash]));
    list.push(ethers.utils.solidityPack(['address'], [header.coinbase]));
    list.push(ethers.utils.solidityPack(['bytes32'], [header.state_root]));
    list.push(ethers.utils.solidityPack(['bytes32'], [header.transactions_root]));
    list.push(ethers.utils.solidityPack(['bytes32'], [header.receipts_root]));
    list.push(ethers.utils.solidityPack(['bytes'], [header.log_bloom]));
    // These are Uint type
    list.push(header.difficulty);
    list.push(header.number);
    list.push(header.gas_limit);
    list.push(header.gas_used);
    list.push(header.timestamp);
    // Exlude last signatures
    list.push(ethers.utils.solidityPack(['bytes'], [header.extra_data.substring(0, header.extra_data.length - 65 * 2)]));

    list.push(ethers.utils.solidityPack(['bytes32'], [header.mix_digest]));
    list.push(ethers.utils.solidityPack(['bytes8'], [header.nonce]));
    let encoded = RLP.encode(list);
    let encodedStr = Buffer.from(encoded).toString('hex');
    let signature = header.extra_data.substring(header.extra_data.length - 65 * 2);
    // console.log('RLP encoded value is ', encodedStr);
    return [encoded, signature];
}

describe("test bsc header", function () {
    this.timeout(6000 * 1000);

    let circuit: any;

    before(async function () {
        console.log("Initialize the circuit test_rlp with wasm tester");
        circuit = await wasm_tester(path.join(__dirname, "../circuits", "bsc_header.circom"));
        // circuit = await wasm_tester(path.join(__dirname, "../circuits", "bsc_header.circom"), { output: "./bsc_circuit_out", recompile: false });
        await circuit.loadConstraints();
        console.log("constraints: " + circuit.constraints.length);
    });


    it("test bsc header", async () => {
        console.log("Start test bsc header");
        const chainId = 56;
        const header = headers[0];
        const [encoded, signature] = get_bsc_message_rlp(header, chainId);

        const pubAddress = header.coinbase;
        const RLP_CIRCUIT_MAX_INPUT_LEN = 1075;

        const input = new Array(RLP_CIRCUIT_MAX_INPUT_LEN);
        for (let i = 0; i < encoded.length; i++) {
            input[i] = BigInt(encoded[i]);
        }
        // pad input
        for (let i = encoded.length; i < RLP_CIRCUIT_MAX_INPUT_LEN; i++) {
            input[i] = 0n;
        }
        const r = hexStringToBigIntArray(signature.substring(0, 64), 4);
        const s = hexStringToBigIntArray(signature.substring(64, 128), 4);
        const v = hexStringToUint8Array(signature.substring(128))[0];

        console.log("start calculating witness");
        const witness = await circuit.calculateWitness(
            {
                "data": input,
                "len": encoded.length,
                "r": r,
                "s": s,
                "v": v,
            });

        const pubKey0 = witness.slice(4, 8);
        const pubKey1 = witness.slice(8, 12);
        const hash64s = witness.slice(12, 16);
        console.log("pubKey0: ", pubKey0);
        console.log("pubKey1: ", pubKey1);
        console.log("hash64s: ", hash64s);
        // account address == coinbase
        expect(witness[1]).to.equal(BigInt(header.coinbase));
        // chain ID
        expect(witness[2]).to.equal(BigInt(chainId));
        // block number
        expect(witness[3]).to.equal(BigInt(header.number));
        const pxHex = uint64ArrayToHexString(pubKey0);
        const pyHex = uint64ArrayToHexString(pubKey1)
        console.log("pxHex: ", pxHex);
        console.log("pyHex: ", pyHex);
        const pubKey = "0x" + "04" + pxHex + pyHex;
        // const pubKey = "0x" + "02" + pxHex;
        console.log("pubkey: ", pubKey);
        const address = ethers.utils.computeAddress(pubKey);
        console.log("address: ", address);
        // const hash = "0x" + uint8ArrayToHexString([47, 23, 206, 197, 127, 147, 238, 27, 221, 135, 239, 15, 62, 207, 115, 45, 64, 214, 88, 58, 211, 217, 210, 67, 86, 155, 32, 59, 221, 249, 83, 123].reverse());
        const hash = "0x" + uint64ArrayToHexString(hash64s);
        const expected = ethers.utils.recoverAddress(hash, {
            r: "0x0670403d7dfc4c816a313885fe04b850f96f27b2e9fd88b147c882ad7caf9b96",
            s: "0x4abfe6543625fcca73b56fe29d3046831574b0681d52bf5383d6f2187b6276c1",
            v: 0,
        });
        expect(address).to.equal(expected);
        await circuit.checkConstraints(witness);
    });
});

describe("signature testing", () => {
    it("just compute address", () => {
        // const px = [15962832680284086442n, 8598231863319617283n, 12189755684745873662n, 7283543198971106409n];
        // const py = [5523025989901260818n, 4498307467847780390n, 14638455475173373968n, 4620569585519891800n];
        const px = [3151177540031678909n, 527654801077446180n, 16504786982926278287n, 15480187017563398766n];
        const py = [1773976871199529362n, 8342164731351105428n, 11426386704715125905n, 13229663652838081723n];
        const pxHex = uint64ArrayToHexString(px);
        const pyHex = uint64ArrayToHexString(py)
        const pubKey = "0x" + "04" + pxHex + pyHex;
        // const pubKey = "0x" + "02" + pxHex;
        console.log("pubkey: ", pubKey);
        const address = ethers.utils.computeAddress(pubKey);

        const hash = "0x" + uint8ArrayToHexString([47, 23, 206, 197, 127, 147, 238, 27, 221, 135, 239, 15, 62, 207, 115, 45, 64, 214, 88, 58, 211, 217, 210, 67, 86, 155, 32, 59, 221, 249, 83, 123].reverse());
        const expected = ethers.utils.recoverAddress(hash, {
            r: "0x0670403d7dfc4c816a313885fe04b850f96f27b2e9fd88b147c882ad7caf9b96",
            s: "0x4abfe6543625fcca73b56fe29d3046831574b0681d52bf5383d6f2187b6276c1",
            v: 0,
        });
        console.log("hash: ", hash);
        console.log("expected: ", expected);
        expect(address).to.equal(expected);
    });
})
