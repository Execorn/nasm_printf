#include <stdio.h>
extern void my_printf();

int main () {
    my_printf("Hello %s! Python is %d times slower than C.\n", "world", 20);
    return 0;
}