# Golden (clean) design sources

| Prefix | Source | Notes |
|---|---|---|
| `os_uart_*`, `os_i2c_*`, `os_axis_*` | https://github.com/alexforencich/verilog-uart, verilog-i2c, verilog-axis | Real open-source RTL, testbenches removed |
| `os_aes_*`, `os_sha256_*`, `os_sha1_*`, `os_chacha_*`, `os_blake2s_*`, `os_siphash_*`, `os_trng_*` | https://github.com/secworks (aes, sha256, sha1, chacha, blake2s, siphash, trng) | Real open-source crypto cores, testbenches removed |
| everything else (e.g. `uart_tx.v`, `mips_alu_32.v`, `iscas_c432.v`) | Hand-written / AI-written simplified designs | NOT the official benchmarks; `iscas_*` are ISCAS-inspired, not the real netlists |

See each repo's LICENSE file before redistributing.
