all: my_printf.out
		./my_printf.out

my_printf.out: main.obj my_printf.obj
		gcc -no-pie -g main.obj my_printf.obj -o my_printf.out

my_printf.obj: my_printf.s
		nasm -f elf64 my_printf.s -o my_printf.obj

main.obj: main.c
		gcc -c -g -no-pie main.c -o main.obj
