# Programming from the Ground Up

Experiment from book [Programming from the Ground
Up](https://download-mirror.savannah.gnu.org/releases/pgubook/ProgrammingGroundUp-1-0-booksize.pdf).

## Make Executable from Assembly File

On 32-bit system, we can use this command to create executable file from
assembly file:
```sh
as -o <file>.o <file>.s # Assembly the program into object code.
ld -o <file> <file>.o # Combine the object code into executable.
```

If we use 64-bit system, we can use this command instead:
```sh
as --32 -o <file>.o <file>.s # Assembly the program into object code.
ld -m elf_i386 -o <file> <file>.o # Combine the object code into executable.
```

This book using 32-bit assembly code, and there's some differences whether we
are using this 32-bit assembly code on 32-bit system or 64-bit system.
Reference:<br>
https://stackoverflow.com/a/36901649
