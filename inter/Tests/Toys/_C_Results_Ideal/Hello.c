typedef int i7val;
typedef char i7byte;
#include <stdio.h>
#define Grammar__Version 2
i7val debug_flag = 0;
i7val KindHierarchy[] = { 0, 0 };
i7val Main(void) {
    printf("%s", "Hello, world.\n");
    exit(0);

}

int main(int argc, char **argv) { Main(); return 0; }
