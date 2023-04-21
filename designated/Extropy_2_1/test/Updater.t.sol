// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Updater.sol";
import "../src/Verifier.sol";
import {Header, HeaderReturn} from "../src/Updater.sol";

contract UpdaterTest is Test {
    Updater public updater;
    Verifier public verifier;
    BatchVerifier public batchVerifier;

    Pi validProof =
        Pi({
            a: [uint(1), uint(2)],
            b: [[uint(1), uint(2)], [uint(1), uint(2)]],
            c: [uint(1), uint(2)],
            input: [uint(1), uint(2)]
        });

    Pi invalidProof =
        Pi({
            a: [uint(2), uint(2)],
            b: [[uint(2), uint(2)], [uint(1), uint(2)]],
            c: [uint(2), uint(2)],
            input: [uint(2), uint(2)]
        });

    function setUp() public {
        verifier = new Verifier();
        batchVerifier = new BatchVerifier();
        updater = new Updater(verifier, batchVerifier);
    }

    function testSetHeader() public {
        Header memory header1 = (
            updater.getHeader(
                bytes32(
                    0x1111111111111111111111111111111111111111111111111111111111111111
                )
            )
        ).header;
        Header memory header2 = Header({
            slot: 2,
            proposerIndex: 2,
            parentRoot: bytes32(
                0x1111111111111111111111111111111111111111111111111111111111111111
            ),
            stateRoot: bytes32(
                0x2222222222222222222222222222222222222222222222222222222222222222
            ),
            bodyRoot: bytes32(
                0x2222222222222222222222222222222222222222222222222222222222222222
            ),
            isValid: true
        });

        assertEq(updater.headerUpdate(validProof, header2, header1), true);

        // get the header
        HeaderReturn memory headerReturn = updater.getHeader(
            bytes32(
                0x2222222222222222222222222222222222222222222222222222222222222222
            )
        );
        assertEq(headerReturn.found, true);
        assertEq(
            headerReturn.header.parentRoot,
            bytes32(
                0x1111111111111111111111111111111111111111111111111111111111111111
            )
        );
    }

    function testSetHeaderReturnsFalseForInvalidProof() public {
        Header memory header1 = (
            updater.getHeader(
                bytes32(
                    0x1111111111111111111111111111111111111111111111111111111111111111
                )
            )
        ).header;
        Header memory header2 = Header({
            slot: 2,
            proposerIndex: 2,
            parentRoot: bytes32(
                0x1111111111111111111111111111111111111111111111111111111111111111
            ),
            stateRoot: bytes32(
                0x2222222222222222222222222222222222222222222222222222222222222222
            ),
            bodyRoot: bytes32(
                0x2222222222222222222222222222222222222222222222222222222222222222
            ),
            isValid: true
        });

        assertEq(updater.headerUpdate(invalidProof, header2, header1), false);
    }

    function testSetHeaderReturnsFalseIfPrevHeaderIsNotInDAG() public {
        Header memory header2 = Header({
            slot: 2,
            proposerIndex: 2,
            parentRoot: bytes32(
                0x1111111111111111111111111111111111111111111111111111111111111111
            ),
            stateRoot: bytes32(
                0x2222222222222222222222222222222222222222222222222222222222222222
            ),
            bodyRoot: bytes32(
                0x2222222222222222222222222222222222222222222222222222222222222222
            ),
            isValid: true
        });

        Header memory header3 = Header({
            slot: 3,
            proposerIndex: 3,
            parentRoot: bytes32(
                0x2222222222222222222222222222222222222222222222222222222222222222
            ),
            stateRoot: bytes32(
                0x3333333333333333333333333333333333333333333333333333333333333333
            ),
            bodyRoot: bytes32(
                0x3333333333333333333333333333333333333333333333333333333333333333
            ),
            isValid: true
        });

        assertEq(updater.headerUpdate(validProof, header3, header2), false);
    }

    function testFailSetHeaderIfHeadersAreNotSubsequent() public {
        Header memory header1 = (
            updater.getHeader(
                bytes32(
                    0x1111111111111111111111111111111111111111111111111111111111111111
                )
            )
        ).header;

        Header memory header3 = Header({
            slot: 3,
            proposerIndex: 3,
            parentRoot: bytes32(
                0x2222222222222222222222222222222222222222222222222222222222222222
            ),
            stateRoot: bytes32(
                0x3333333333333333333333333333333333333333333333333333333333333333
            ),
            bodyRoot: bytes32(
                0x3333333333333333333333333333333333333333333333333333333333333333
            ),
            isValid: true
        });

        updater.headerUpdate(validProof, header3, header1);
    }

    function testGetHeader() public {
        HeaderReturn memory headerReturn = updater.getHeader(
            bytes32(
                0x1111111111111111111111111111111111111111111111111111111111111111
            )
        );
        assertEq(headerReturn.found, true);
        assertEq(
            headerReturn.header.parentRoot,
            bytes32(
                0x0000000000000000000000000000000000000000000000000000000000000000
            )
        );
    }

    function testGetNotExistingHeader() public {
        HeaderReturn memory headerReturn = updater.getHeader(
            bytes32(
                0x9999999999999999999999999999999999999999999999999999999999999999
            )
        );
        assertEq(headerReturn.found, false);
    }

    function _createHeaderBatch() internal returns (Header[] memory) {
        Header[] memory headerBatch = new Header[](3);
        headerBatch[0] = Header({
            slot: 2,
            proposerIndex: 2,
            parentRoot: bytes32(
                0x1111111111111111111111111111111111111111111111111111111111111111
            ),
            stateRoot: bytes32(
                0x2222222222222222222222222222222222222222222222222222222222222222
            ),
            bodyRoot: bytes32(
                0x2222222222222222222222222222222222222222222222222222222222222222
            ),
            isValid: true
        });
        headerBatch[1] = Header({
            slot: 3,
            proposerIndex: 3,
            parentRoot: bytes32(
                0x2222222222222222222222222222222222222222222222222222222222222222
            ),
            stateRoot: bytes32(
                0x3333333333333333333333333333333333333333333333333333333333333333
            ),
            bodyRoot: bytes32(
                0x3333333333333333333333333333333333333333333333333333333333333333
            ),
            isValid: true
        });
        headerBatch[2] = Header({
            slot: 4,
            proposerIndex: 4,
            parentRoot: bytes32(
                0x3333333333333333333333333333333333333333333333333333333333333333
            ),
            stateRoot: bytes32(
                0x4444444444444444444444444444444444444444444444444444444444444444
            ),
            bodyRoot: bytes32(
                0x4444444444444444444444444444444444444444444444444444444444444444
            ),
            isValid: true
        });

        return headerBatch;
    }

    function testIncorrectBatchProof() public {
        Header[] memory headerBatch = _createHeaderBatch();
        assertEq(updater.batchHeaderUpdate(invalidProof, headerBatch), false);
    }

    function testCorrectBatchProof() public {
        Header[] memory headerBatch = _createHeaderBatch();
        assertEq(updater.batchHeaderUpdate(validProof, headerBatch), true);
        HeaderReturn memory headerReturn = updater.getHeader(
            bytes32(
                0x2222222222222222222222222222222222222222222222222222222222222222
            )
        );
        assertEq(headerReturn.found, true);
        assertEq(
            headerReturn.header.parentRoot,
            bytes32(
                0x1111111111111111111111111111111111111111111111111111111111111111
            )
        );
    }

    function testGetCurrentPeriod() public {
        vm.warp(1682063593);
        uint64 period = updater.getSyncCommitteePeriodFromSlot(
            updater.getCurrentSlot()
        );
        assert(period > 0);
    }

    function testSetSyncCommitteeRoot() public {
        vm.warp(1682063622);
        uint64 period = updater.getSyncCommitteePeriodFromSlot(
            updater.getCurrentSlot()
        );
        updater.setSyncCommitteeRoot(
            period,
            0x3142300d4222b4b79b94c2d88b1d625e4d7c9a483a5108afaed1699f7547ceb3
        );
    }
}
