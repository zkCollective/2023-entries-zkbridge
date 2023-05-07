pragma circom 2.0.1;

include "./circom-ecdsa/ecdsa.circom";
include "./keccak256-circom/keccak.circom";
include "./rlp/rlp.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";

function min(a, b) {
    if(a < b)
        return a;
    return b;
}

function max(a, b) {
    if(a > b)
        return a;
    return b;
}

template ShiftRight(nIn, nInBits) {
    signal input in[nIn];
    signal input shift;
    signal output out[nIn];

    component n2b = Num2Bits(nInBits);
    n2b.in <== shift;

    signal shifts[nInBits][nIn];
    for (var idx = 0; idx < nInBits; idx++) {
        if (idx == 0) {
	        for (var j = 0; j < min((1 << idx), nIn); j++) {
                shifts[0][j] <== - n2b.out[idx] * in[j] + in[j];
            }
	        for (var j = (1 << idx); j < nIn; j++) {
	            var tempIdx = j - (1 << idx);
                shifts[0][j] <== n2b.out[idx] * (in[tempIdx] - in[j]) + in[j];
            }
        } else {
            for (var j = 0; j < min((1 << idx), nIn); j++) {
                var prevIdx = idx - 1;
                shifts[idx][j] <== - n2b.out[idx] * shifts[prevIdx][j] + shifts[prevIdx][j];
            }
            for (var j = (1 << idx); j < nIn; j++) {
                var prevIdx = idx - 1;
                var tempIdx = j - (1 << idx);
                shifts[idx][j] <== n2b.out[idx] * (shifts[prevIdx][tempIdx] - shifts[prevIdx][j]) + shifts[prevIdx][j];
            }
        }
    }
    for (var i = 0; i < nIn; i++) {
        out[i] <== shifts[nInBits - 1][i];
    }
}

template bytesToBigInt(n) {
    signal input in[n];
    signal input inHexLen;
    signal output out;

    assert(n <= 64);
    component shiftRight = ShiftRight(n, 6);
    shiftRight.in <== in;
    shiftRight.shift <== n - inHexLen;

    var temp = 0;
    for (var idx = 0; idx < n; idx++) {
        temp = 256 * temp + shiftRight.out[idx];
    }
    out <== temp;
}

template BSCHeaderVerification() {
    var maxLen = 1075;
    // RLP representation of the bsc header in bytes
    signal input data[maxLen]; // 1075 bytes of RLP encoding
    // RLP data length
    signal input len;
    // validator signature in hex(4-bit)
    signal input r[4];
    signal input s[4];
    signal input v; // 0, 1, 2, 3

    // bsc header fields
    signal output coinbase;
    signal output chainId;
    signal output blockNumber;
    // validator public key in hex(4-bit)
    signal output pubKey[2][4];
    // bsc header hash in hex(4-bit)
    signal output hashValue[4];

    // RLP stuff
    component rlp = RLPDecodeFixedList(
        maxLen,
        16,
        [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
        [1,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0],
        [0,  32, 32, 20, 32, 32, 32, 256,  0,  0,  0,  0,  0,  32, 32, 8],
        [32, 32, 32, 20, 32, 32, 32, 256, 32, 32,  8,  8,  8, 452, 32, 8],
        0);

    for (var idx = 0; idx < maxLen; idx++) {
    	rlp.data[idx] <== data[idx];
    }

    // account address
    var temp = 0;
    for (var idx = 0; idx < 20; idx++) {
        temp = 256 * temp + rlp.fields[3][idx];
    }
    coinbase <== temp;
    log("account address is:");
    log(coinbase);

    // chain ID
    component b2b = bytesToBigInt(32);
    for (var idx = 0; idx < 32; idx++) {
        b2b.in[idx] <== rlp.fields[0][idx];
    }
    b2b.inHexLen <== rlp.fieldLens[0];
    chainId <== b2b.out;
    log("chain ID is:");
    log(chainId);

    // block number
    component b2bNumber = bytesToBigInt(32);
    for (var idx = 0; idx < 32; idx++) {
        b2bNumber.in[idx] <== rlp.fields[9][idx];
    }
    b2bNumber.inHexLen <== rlp.fieldLens[9];
    blockNumber <== b2bNumber.out;
    log("block number is:");
    log(blockNumber);

    component hash = KeccakV(1075 * 8, 256);
    component n2b[1075];
    for (var i = 0; i < 1075; i++) {
        n2b[i] = Num2Bits(8);
        n2b[i].in <== data[i];
        for (var j = 0; j < 8; j++) {
            hash.in[i * 8 + j] <== n2b[i].out[j];
        }
    }
    hash.len <== len * 8;

    component erecover = ECDSARecover(64, 4);
    component b2n[4];
    for (var i = 0; i < 4; i++) {
        erecover.r[i] <== r[i];
        erecover.s[i] <== s[i];
        b2n[i] = Bits2Num(64);
        for (var j = 0; j < 64; j++) {
            b2n[i].in[j] <== hash.out[i * 64 + j];
        }
        erecover.msghash[i] <== b2n[i].out;
        hashValue[i] <== b2n[i].out;
    }
    erecover.v <== v;
    for (var i = 0; i < 4; i++) {
        pubKey[0][i] <== erecover.pubKey[0][i];
        pubKey[1][i] <== erecover.pubKey[1][i];
    }
}

component main = BSCHeaderVerification();
