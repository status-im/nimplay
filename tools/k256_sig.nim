import os

import nimcrypto



proc main() =
    if paramCount() != 1:
        echo("Requires single parameter to be hashed")
        quit()

    echo(keccak256.digest(commandLineParams()[0])))


when is_main_module:
    main()
