execute: my_printf.out
		./my_printf.out

my_printf.out: main.obj my_printf.obj
		gcc -no-pie main.obj my_printf.obj -o my_printf.out

my_printf.obj: my_printf.s
		nasm -f elf64 my_printf.s -o my_printf.obj

main.obj: main.c
		gcc -c -no-pie main.c -o main.obj