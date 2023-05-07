// Keccak256 hash function (ethereum version).
// For LICENSE check https://github.com/vocdoni/keccak256-circom/blob/master/LICENSE

pragma circom 2.0.0;

include "./utils.circom";
include "./permutations.circom";
include "../../../node_modules/circomlib/circuits/comparators.circom";
include "../../../node_modules/circomlib/circuits/switcher.circom";

template Pad(nBits) {
    signal input in[nBits];

    var blockSize=136*8;
    signal output out[blockSize];
    signal out2[blockSize];

    var i;

    for (i=0; i<nBits; i++) {
        out2[i] <== in[i];
    }
    var domain = 0x01;
    for (i=0; i<8; i++) {
        out2[nBits+i] <== (domain >> i) & 1;
    }
    for (i=nBits+8; i<blockSize; i++) {
        out2[i] <== 0;
    }
    component aux = OrArray(8);
    for (i=0; i<8; i++) {
        aux.a[i] <== out2[blockSize-8+i];
        aux.b[i] <== (0x80 >> i) & 1;
    }
    for (i=0; i<8; i++) {
        out[blockSize-8+i] <== aux.out[i];
    }
    for (i=0; i<blockSize-8; i++) {
        out[i]<==out2[i];
    }
}

template PadV() {
    var blockSize=136*8;

    signal input in[blockSize];
    signal input len;
    signal output out[blockSize];
    assert(len <= blockSize);

    component is_eq[blockSize-1];
    component less_than[blockSize-1];
    component sw1[blockSize-1];
    component sw2[blockSize-1];
    for (var i = 0; i < blockSize-1; i++) {
        is_eq[i] = IsEqual();
        is_eq[i].in[0] <== i;
        is_eq[i].in[1] <== len;
        sw1[i] = Switcher();
        sw1[i].L <== in[i];
        sw1[i].R <== 1;
        sw1[i].sel <== is_eq[i].out;

        less_than[i] = LessThan(num_bits(blockSize));
        less_than[i].in[0] <== i;
        less_than[i].in[1] <== len + 1; // for i <= len, we'd like to keep the original input (with the padded 1)
        sw2[i] = Switcher();
        sw2[i].L <== sw1[i].outL;
        sw2[i].R <== 0;
        sw2[i].sel <== 1 - less_than[i].out;

        out[i] <== sw2[i].outL;
    }
    out[blockSize-1] <== 1;
}

template KeccakfRound(r) {
    signal input in[25*64];
    signal output out[25*64];
    var i;

    component theta = Theta();
    component rhopi = RhoPi();
    component chi = Chi();
    component iota = Iota(r);

    for (i=0; i<25*64; i++) {
        theta.in[i] <== in[i];
    }
    for (i=0; i<25*64; i++) {
        rhopi.in[i] <== theta.out[i];
    }
    for (i=0; i<25*64; i++) {
        chi.in[i] <== rhopi.out[i];
    }
    for (i=0; i<25*64; i++) {
        iota.in[i] <== chi.out[i];
    }
    for (i=0; i<25*64; i++) {
        out[i] <== iota.out[i];
    }
}

template Absorb() {
    var blockSizeBytes=136;

    signal input s[25*64];
    signal input block[blockSizeBytes*8];
    signal output out[25*64];
    var i;
    var j;

    component aux[blockSizeBytes/8];
    component newS = Keccakf();

    for (i=0; i<blockSizeBytes/8; i++) {
        aux[i] = XorArray(64);
        for (j=0; j<64; j++) {
            aux[i].a[j] <== s[i*64+j];
            aux[i].b[j] <== block[i*64+j];
        }
        for (j=0; j<64; j++) {
            newS.in[i*64+j] <== aux[i].out[j];
        }
    }
    // fill the missing s that was not covered by the loop over
    // blockSizeBytes/8
    for (i=(blockSizeBytes/8)*64; i<25*64; i++) {
            newS.in[i] <== s[i];
    }
    for (i=0; i<25*64; i++) {
        out[i] <== newS.out[i];
    }
}

template Final(nBits) {
    signal input in[nBits];
    signal output out[25*64];
    var blockSize=136*8;
    var i;

    // pad
    component pad = Pad(nBits);
    for (i=0; i<nBits; i++) {
        pad.in[i] <== in[i];
    }
    // absorb
    component abs = Absorb();
    for (i=0; i<blockSize; i++) {
        abs.block[i] <== pad.out[i];
    }
    for (i=0; i<25*64; i++) {
        abs.s[i] <== 0;
    }
    for (i=0; i<25*64; i++) {
        out[i] <== abs.out[i];
    }
}

template FinalV() {
    var blockSize=136*8;
    var stateSize=25*64;

    signal input in[blockSize];
    signal input len;
    signal input s[stateSize];
    signal output out[stateSize];
    var i;

    // pad
    component pad = PadV();
    for (i=0; i<blockSize; i++) {
        pad.in[i] <== in[i];
    }
    pad.len <== len;
    // absorb
    component abs = Absorb();
    for (i=0; i<blockSize; i++) {
        abs.block[i] <== pad.out[i];
    }
    for (i=0; i<stateSize; i++) {
        abs.s[i] <== s[i];
    }
    for (i=0; i<stateSize; i++) {
        out[i] <== abs.out[i];
    }
}

template Squeeze(nBits) {
    signal input s[25*64];
    signal output out[nBits];
    var i;
    var j;

    for (i=0; i<25; i++) {
        for (j=0; j<64; j++) {
            if (i*64+j<nBits) {
                out[i*64+j] <== s[i*64+j];
            }
        }
    }
}

template Keccakf() {
    signal input in[25*64];
    signal output out[25*64];
    var i;
    var j;

    // 24 rounds
    component round[24];
    signal midRound[24*25*64];
    for (i=0; i<24; i++) {
        round[i] = KeccakfRound(i);
        if (i==0) {
            for (j=0; j<25*64; j++) {
                midRound[j] <== in[j];
            }
        }
        for (j=0; j<25*64; j++) {
            round[i].in[j] <== midRound[i*25*64+j];
        }
        if (i<23) {
            for (j=0; j<25*64; j++) {
                midRound[(i+1)*25*64+j] <== round[i].out[j];
            }
        }
    }

    for (i=0; i<25*64; i++) {
        out[i] <== round[23].out[i];
    }
}

template Keccak(nBitsIn, nBitsOut) {
    assert(nBitsIn < 136*8);
    signal input in[nBitsIn];
    signal output out[nBitsOut];
    var i;

    component f = Final(nBitsIn);
    for (i=0; i<nBitsIn; i++) {
        f.in[i] <== in[i];
    }
    component squeeze = Squeeze(nBitsOut);
    for (i=0; i<25*64; i++) {
        squeeze.s[i] <== f.out[i];
    }
    for (i=0; i<nBitsOut; i++) {
        out[i] <== squeeze.out[i];
    }
}

template BlockDivision(nBitsIn) {
    signal input in;
    signal output quotient;
    signal output remainder;
    var blockSize = 136*8;

    remainder <-- in % blockSize;
    component lt = LessThan(num_bits(blockSize));
    lt.in[0] <== remainder;
    lt.in[1] <== blockSize;
    lt.out === 1;

    quotient <-- in \ blockSize;
    quotient * blockSize + remainder === in;
}

template AbsorbOrThrough() {
    var blockSize=136*8;
    var stateSize = 25*64;

    signal input s[stateSize];
    signal input block[blockSize];
    signal input is_absorb;
    signal output out[stateSize];

    component absorb = Absorb();

    for (var i = 0; i < blockSize; i++) {
        absorb.block[i] <== block[i];
    }
    for (var i = 0; i < stateSize; i++) {
        absorb.s[i] <== s[i];
    }

    component out_switcher[stateSize];
    for (var i = 0; i < stateSize; i++) {
        out_switcher[i] = Switcher();
        out_switcher[i].L <== s[i];
        out_switcher[i].R <== absorb.out[i];
        out_switcher[i].sel <== is_absorb;

        out[i] <== out_switcher[i].outL;
    }
}

template ShiftLeftBlock(nIn) {
    var blockSize = 136*8;
    signal input in[nIn];
    signal input doShift;
    signal output out[nIn];

    signal shifted[nIn];
    for (var i = 0; i < nIn; i++) {
        shifted[i] <== in[(i+blockSize)%nIn];
    }
    component switcher[nIn];
    for (var i = 0; i < nIn; i++) {
        switcher[i] = Switcher();
        switcher[i].L <== in[i];
        switcher[i].R <== shifted[i];
        switcher[i].sel <== doShift;

        out[i] <== switcher[i].outL;
    }
}

template KeccakV(maxBitsIn, nBitsOut) {
    var nBlocks = (maxBitsIn + 136*8 - 1) \ (136*8);
    var blockSize = 136*8;
    var stateSize = 25*64;
    signal input in[maxBitsIn];
    signal input len;

    signal output out[nBitsOut];

    component bd = BlockDivision(maxBitsIn);
    bd.in <== len;
    var numAbsorbBlocks = bd.quotient;
    var finalLen = bd.remainder;

    var maxAbsorbBlocks = nBlocks - 1;
    component absorbs[maxAbsorbBlocks];
    component isAbsorb[maxAbsorbBlocks];
    component leftShift[maxAbsorbBlocks];

    var finalInS[stateSize];
    var shifted[maxBitsIn] = in;
    if (maxAbsorbBlocks == 0) {
        for (var i = 0; i < stateSize; i++) {
            finalInS[i] = 0;
        }
    } else {
        for (var i = 0; i < maxAbsorbBlocks; i++) {
            isAbsorb[i] = LessThan(num_bits(maxAbsorbBlocks));
            isAbsorb[i].in[0] <== i;
            isAbsorb[i].in[1] <== numAbsorbBlocks;

            absorbs[i] = AbsorbOrThrough();
            absorbs[i].is_absorb <== isAbsorb[i].out;
            for (var j = 0; j < blockSize; j++) {
                absorbs[i].block[j] <== shifted[j];
            }
            if (i == 0) {
                for (var j = 0; j < stateSize; j++) {
                    absorbs[i].s[j] <== 0;
                }
            } else {
                for (var j = 0; j < stateSize; j++) {
                    absorbs[i].s[j] <== absorbs[i-1].out[j];
                }
            }
            leftShift[i] = ShiftLeftBlock(maxBitsIn);
            leftShift[i].doShift <== isAbsorb[i].out;
            for (var j = 0; j < maxBitsIn; j++) {
                leftShift[i].in[j] <== shifted[j];
            }
            shifted = leftShift[i].out;
        }
        finalInS = absorbs[maxAbsorbBlocks-1].out;
    }

    component f = FinalV();
    for (var i = 0; i < stateSize; i++) {
        f.s[i] <== finalInS[i];
    }
    for (var i = 0; i < blockSize; i++) {
        f.in[i] <== shifted[i];
    }
    f.len <== finalLen;

    component squeeze = Squeeze(nBitsOut);
    for (var i=0; i<stateSize; i++) {
        squeeze.s[i] <== f.out[i];
    }
    for (var i=0; i<nBitsOut; i++) {
        out[i] <== squeeze.out[i];
    }
}
