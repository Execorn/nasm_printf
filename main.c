#include <stdio.h>
extern void my_printf();

int main () {
    my_printf("Hello %s!\n", "world");
    return 0;
}