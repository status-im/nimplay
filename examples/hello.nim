import ../eth_contracts

proc hello(): int64 =
    return 1234567

proc main() {.exportwasm.} =
    var res: int64 = 1234567
    finish(addr res, sizeof(res).int32)


discard """
[
    {
        "name": "hello",
        "outputs": [
            {
                "type": "int64",
                "name": "out"
            }
        ],
        "inputs": [
            {
                "type": "int64",
                "name": "a"
            },
            {
                "type": "int64",
                "name": "b"
            }
        ],
        "constant": false,
        "payable": false,
        "type": "function",
    }
]
"""
