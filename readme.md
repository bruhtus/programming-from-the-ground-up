# Programming from the Ground Up

## Make Executable from Assembly File

To create executable file from assembly file, we can use this command:
```sh
as -o <file>.o <file>.s # Assembly the program into object code.
ld -o <file> <file>.o # Combine the object code into executable.
```
