# Programming from the Ground Up

Experiment from book [Programming from the Ground
Up](https://download-mirror.savannah.gnu.org/releases/pgubook/ProgrammingGroundUp-1-0-booksize.pdf).

## Make Executable from Assembly File

To create executable file from assembly file, we can use this command:
```sh
as -o <file>.o <file>.s # Assembly the program into object code.
ld -o <file> <file>.o # Combine the object code into executable.
```
