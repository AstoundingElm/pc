/*#foreign(header = "<string.h>")

@foreign
func memcpy(s1: void*, s2: void *, n: usize): void*;

@foreign
func memmove(s1: void*, s2: void *, n: usize): void*;

@foreign
func strcpy(s1: char*, s2: char*): char*;

@foreign
func strncpy(s1: char*, s2: char*, n: usize): char*;

@foreign
func strcat(s1: char*, s2: char*): char*;

@foreign
func strncat(s1: char*, s2: char*, n: usize): char*;

@foreign
func memcmp(s1: void *, s2: void *, n: usize): int;

@foreign
func strcmp(s1: char*, s2: char*): int;

@foreign
func strcoll(s1: char*, s2: char*): int;

@foreign
func strncmp(s1: char*, s2: char*, n: usize): int;

@foreign
func strxfrm(s1: char*, s2: char*, n: usize): usize;

@foreign
func memchr(s: void *, c: int, n: usize): void*;

@foreign
func strchr(s: char*, c: int): char*;

@foreign
func strcspn(s1: char*, s2: char*): usize;

@foreign
func strpbrk(s1: char*, s2: char*): char*;

@foreign
func strrchr(s: char*, c: int): char*;

@foreign
func strspn(s1: char*, s2: char*): usize;

@foreign
func strstr(s1: char*, s2: char*): char*;

@foreign
func strtok(s1: char*, s2: char*): char*;

@foreign
func memset(s: void*, c: int, n: usize): void*;

@foreign
func strerror(errnum: int): char*;

@foreign
func strlen(s: char*): usize;

@foreign
func strdup(s : char*): char *;*/
@foreign
func strchr(s: char*, c: int): char*;
