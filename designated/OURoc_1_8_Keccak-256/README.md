## Keccak-256

The work here is based on previous work in [vocdoni/keccak256-circom](https://github.com/vocdoni/keccak256-circom). The repo only had support for fixed-size input with a maximum length of one block (136 * 8 bits). This won't be desirable for most use cases where there will be variable-sized data and has size larger than the limit.

We implemented an enhanced version of keccak that can handle variabled-sized input of data with no max length limit. The main template frunction is `KeccakV` in `keccak.circom`. This enables the circuit to be applicable for a lot more use cases.

### Build

```
npm i
```

### Test

```
npm test -- --grep "KeccakV"
```