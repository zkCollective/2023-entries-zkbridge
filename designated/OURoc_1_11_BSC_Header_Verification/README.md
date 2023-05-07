## BSC single block header verification

The final task combines the effort from all of the other three tasks (1_2, 1_3, 1_8). We implemented a bsc single block verifier in Circom that decodes and validates an RLP-encoded BSC block header, and returns the recovered public key which can be further validated on-chain to determine if the block is signed by a valid validator.

The result is `bsc_header.circom`.

### Build

```
npm i
```

### Test

```
npm test
```

Compiling circuit for the project might fail because the stderr (compiler warnings) size exceeds the default maximum size. There's no way to fix it with the current `wasm_tester`. A workaround would be to update the line in `node_modules\circom_tester\wasm\tester.js` that invokes `circom` in to something like `b = await exec("circom " + flags + fileName, {maxBuffer: 1024*1024*1024});`. Or we could manually compile the circuit to a folder and specify that folder in the test.
