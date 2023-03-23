pragma circom 2.0.1;

include "../../../node_modules/circomlib/circuits/comparators.circom";
include "../../circuits/zk-attestor-rlp.circom";


template bytesToBigInt(n) {
    signal input in[n];
    signal input inHexLen;
    signal output out;

    assert(n <= 64);
    // assume 6 >= log2(n)
    component shiftRight = ShiftRight(n, 6);
    shiftRight.in <== in;
    shiftRight.shift <== n - inHexLen;

    // for (var idx = 0; idx < n; idx++) {
    //     log(shiftRight.out[idx]);
    // }

    var temp = 0;
    for (var idx = 0; idx < n; idx++) {
        temp = 16 * temp + shiftRight.out[idx];
    }
    out <== temp;
}

template TestRLPHeader() {
    // Input, RLP representation of the block.
    signal input in[2150]; // 2150 bytes of RLP encoding
    // Outputs.    
    signal output coinbase;
    signal output chainId;
    signal output blockNumber;

    // RLP stuff
    component rlp = RlpArrayCheck(2150, 16, 4,
        [0,  64, 64, 40, 64, 64, 64, 512,  0,  0,  0,  0,  0,  64, 64, 16],
        [64, 64, 64, 40, 64, 64, 64, 512, 64, 64, 16, 16, 16, 904, 64, 16]);

    for (var idx = 0; idx < 2150; idx++) {
    	rlp.in[idx] <== in[idx];
    }

    // account address
    var temp = 0;
    for (var idx = 0; idx < 40; idx++) {
        temp = 16 * temp + rlp.fields[3][idx];
    }
    coinbase <== temp;
    log("account address is:");
    log(coinbase);

    // chain ID
    component b2b = bytesToBigInt(64);
    for (var idx = 0; idx < 64; idx++) {
        b2b.in[idx] <== rlp.fields[0][idx];
    }
    b2b.inHexLen <== rlp.fieldHexLen[0];
    chainId <== b2b.out;
    log("chain ID is:");
    log(chainId);

    // block number
    component b2bNumber = bytesToBigInt(64);
    for (var idx = 0; idx < 64; idx++) {
        b2bNumber.in[idx] <== rlp.fields[9][idx];
    }
    b2bNumber.inHexLen <== rlp.fieldHexLen[9];
    blockNumber <== b2bNumber.out;
    log("block number is:");
    log(blockNumber);
}

component main {public [in]} = TestRLPHeader();