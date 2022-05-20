#include <stdio.h>
extern void my_printf();
//TODO:
// 1) %d to work with negative
// 2) %x to work 
// 3) %b to work 
int main () {
    //my_printf("Hello %s! Python is %d times slower than C.\n%d %s %d%%%c\n", "world", 20, -1, "love", 100, '!');
    my_printf("Hello %s! Python is %d times slower than C.\n%d %s %x %d%%%c%b\n", "world", 20, -1, "love", 3802, 100, '!', 127);
    return 0;
}