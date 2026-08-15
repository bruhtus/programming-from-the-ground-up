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

## Caller-saved and Callee-saved

To understand what is Caller and Callee, look at this C programming language
snippet:
```c
void caller(void)
{
    callee();
}
```

Basically Caller is the function that call another function, and Callee is the
function that is called by Caller function.

Caller-saved (owned by Callee):<br>
The Callee might _changed_ the value, so the Caller need to save the value
before entering the Callee function.

Callee-saved (owned by Caller):<br>
The Caller might _need_ the value, so the Callee need to save the value before
using the register and restore those value back before returning to the Caller
function.

## References

- [x86_64 linux system call number](https://cigix.me/syscalls)
- [x86_64 common registers](https://math.hws.edu/eck/cs220/f22/registers.html)
