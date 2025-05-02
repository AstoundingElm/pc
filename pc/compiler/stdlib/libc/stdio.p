#foreign(header = "<stdio.h>")

@foreign
struct FILE;

@foreign
var stdin:  FILE*

@foreign
var stdout: FILE*

@foreign
var stderr: FILE*

@foreign
struct fpos_t;

@foreign
typedef va_list = char*;

@foreign const EOF      = -1;
@foreign const SEEK_SET = 0;
@foreign const SEEK_CUR = 1;
@foreign const SEEK_END = 2;

@foreign
func remove(filename: char *): int;

@foreign
func rename(oldname: char *, newname: char *): int;

@foreign
func tmpfile(): FILE*;

@foreign
func tmpnam(s: char*): char*;

@foreign
func fclose(stream: FILE*): int;

@foreign
func fflush(stream: FILE*): int;

@foreign
func fopen(filename: char*, mode: char*): FILE*;

@foreign
func freopen(filename: char*, mode: char*, stream: FILE*): FILE*;

@foreign
func setbuf(stream: FILE*, buf: char*);

@foreign
func setvbuf(stream: FILE*, buf: char*, mode: int, size: usize): int;

@foreign
func fprintf(stream: FILE*, format: char*, ...): int;

@foreign
func fscanf(stream: FILE*, format: char*, ...): int;

@foreign
func printf(format: char*, ...): int;

@foreign
func scanf(format: char*, ...): int;

@foreign
func snprintf(s: char*, n: usize, format: char*, ...): int;

@foreign
func sprintf(s: char*, format: char*, ...): int;

@foreign
func sscanf(s: char*, format: char*, ...): int;

@foreign
func vfprintf(stream: FILE*, format: char*, arg: va_list): int;

@foreign
func vfscanf(stream: FILE*, format: char*, arg: va_list): int;

@foreign
func vprintf(format: char*, arg: va_list): int;

@foreign
func vscanf(format: char*, arg: va_list): int;

@foreign
func vsnprintf(s: char*, n: usize, format: char*, arg: va_list): int;

@foreign
func vsprintf(s: char*, format: char*, arg: va_list): int;

@foreign
func vsscanf(s: char*, format: char*, arg: va_list): int;

@foreign
func fgetc(stream: FILE*): int;

@foreign
func fgets(s: char*, n: int, stream: FILE*): char*;

@foreign
func fputc(c: int, stream: FILE*): int;

@foreign
func fputs(s: char*, stream: FILE*): int;

@foreign
func getc(stream: FILE*): int;

@foreign
func getchar(): int;

@foreign
func gets(s: char*): char*;

@foreign
func putc(c: int, stream: FILE*): int;

@foreign
func putchar(c: int): int;

@foreign
func puts(s: char*): int;

@foreign
func ungetc(c: int, stream: FILE*): int;

@foreign
func fread(ptr: void*, size: usize, nmemb: usize, stream: FILE*): usize;

@foreign
func fwrite(ptr: void *, size: usize, nmemb: usize, stream: FILE*): usize;

@foreign
func fgetpos(stream: FILE*, pos: fpos_t*): int;

@foreign
func fseek(stream: FILE*, offset: long, whence: int): int;

@foreign
func fsetpos(stream: FILE*, pos: fpos_t*): int;

@foreign
func ftell(stream: FILE*): long;

@foreign
func rewind(stream: FILE*);

@foreign
func clearerr(stream: FILE*);

@foreign
func feof(stream: FILE*): int;

@foreign
func ferror(stream: FILE*): int;

@foreign
func perror(s: char*);

