#include <stdio.h>
#include <iostream>
using namespace std;

int main(int argc, char* argv[])
{
    if(argc == 1) {
        printf("Usage: ./read [binary_map_path]\n");
        return 1;
    }
    FILE* file = fopen(argv[1], "rb");
    u_int8_t* map = new u_int8_t[120*29];
    fread(map, sizeof(u_int8_t), 120*29, file);

    for(int i=0; i<120*29; ++i) {
        if(i % 120 == 0)
            cout << endl;
        if(*(map+i) == 1)
            printf("*");
        else
            printf(" ");
    }
    return 0;
}
