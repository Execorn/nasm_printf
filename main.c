#include <stdio.h>
extern void my_printf();

int main () {
    my_printf("Hello %s! Python is %d times slower than C.\n%d %s %x %d%%%c%b\n", "world", 20, -1, "love", 3802, 100, '!', 127);
    return 0;
}