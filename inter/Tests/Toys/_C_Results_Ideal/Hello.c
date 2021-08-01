typedef int i7val;
typedef char i7byte;
#include <stdio.h>
#define i7_mangled_Grammar__Version 2
i7val i7_mangled_debug_flag = 0;
i7val i7_mangled_KindHierarchy[] = { 0, 0 };
i7val i7_mangled_Main(void) {
    printf("%s", "Hello, world.\n");
    exit(0);

}

int main(int argc, char **argv) { i7_mangled_Main(); return 0; }
