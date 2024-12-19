#include <stdio.h>

void
sort(int *array, int len)
{
    for (int i = 0; i < len - 1; i++) {
        for (int j = 0; j < len - i - 1; j++) {
            if (array[j] > array[j + 1]) {
                int temp_val = array[j];
                array[j] = array[j + 1];
                array[j + 1] = temp_val;
            }
        }
    }
}

int
main(void)
{
    int data[7] = {9, 6, 7, 8, 3, 10, 1};
    int len = 7;
    sort(data, len);

    printf("Sorted Array:\n");
    for (int i = 0; i < len; i++) {
        printf("%i ", data[i]);
    }
}