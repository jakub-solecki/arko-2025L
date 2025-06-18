#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

// External assembler function
void desat(void *img, int level);

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s input.bmp level(0–64)\n", argv[0]);
        return 1;
    }

    const char *input_file = argv[1];

    
    int level = atoi(argv[2]);

    if (level < 0 || level > 64) {
        fprintf(stderr, "Level must be between 0 and 64\n");
        return 1;
    }

    FILE *f = fopen(input_file, "rb+");
    if (!f) {
        perror("fopen");
        return 1;
    }

    fseek(f, 0, SEEK_END);
    long filesize = ftell(f);
    rewind(f);

    uint8_t *bmp_data = malloc(filesize);
    if (!bmp_data) {
        fclose(f);
        fprintf(stderr, "Memory allocation failed\n");
        return 1;
    }

    fread(bmp_data, 1, filesize, f);

    // Call assembler function
    desat((void*)bmp_data, level);

    rewind(f);
    fwrite(bmp_data, 1, filesize, f);
    fclose(f);
    free(bmp_data);

    return 0;
}