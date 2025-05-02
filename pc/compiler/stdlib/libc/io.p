/*#foreign(header = "<io.h>")
#foreign var _A_SUBDIR = 0x10;


_finddata_t struct {

    attrib int
    time_create time_t
    time_access time_t
    time_write time_t
    size usize
    name char[260]
}

@foreign("_findfirst")
_findfirst(filespec ^char, fileinfo ^_finddata_t) -> intptr;


@foreign("_findnext")
_findnext(handle intptr, fileinfo ^_finddata_t) -> int;



@foreign("_findclose") _findclose(handle intptr) -> int ;

@foreign("_fullpath")
_fullpath(absPath ^char, relPath ^char, maxLength usize) -> ^char;*/

pc_memcpy(dest ^void, src ^void, num usize) ^void {
    i int
    d: ^char = dest
    s: ^char= src 
    for(i = 0; i < num; i++) {
        d[i] = s[i] 
    }
    return dest
   // return memcpy(dest, src, num)
}

pc_strcmp(s1 ^char, s2 ^char) int {
    while(*s1 && (*s1 == *s2)){
        s1++
        s2++
    }
    return *(: ^uchar)s1 - *(: ^uchar)s2
 // return strcmp(s1, s2)
}

pc_strlen(s ^char) usize {
    p := s
    while(*p) { ++p }
    return p - s
}


pc_strdup(s ^char) ^char {
    size := pc_strlen(s) + 1
    c ^char = malloc(sizeof(char) * size)
    pc_memcpy(c, s, size)
    return c
    //return strdup(s)
}

pc_strcpy(dest ^char, src ^char) ^char {

    temp ^char =  dest
    if(!src || !dest){

        return 0
    }
    do {
       *temp++ = *src
    
    } while (*src++)
     return temp
  //  return strcpy(dest, src)

 
}

pc_strncpy(dest ^char, src ^char, n usize) ^char {
    i usize
    for(i = 0; i < n && src[i] != '\0'; i++){
        dest[i] = src[i]
    }

    for(i = 0; i < n; i++ ){

        dest[i] == '\0'
    }
    return dest
    //return strncpy(dest, src, n)
}

pc_strncmp(s1 ^char, s2 ^char, n usize) int {
    while(n && *s1 && ( *s1 == *s2)) {
        ++s1;
        ++s2;
        --n;
    }
    if(n == 0){
        return 0
    }
    else {
        return ( *(: ^uchar)s1 - *(: ^uchar)s2)
    }
  //  return strncmp(s1, s2, n)
}

pc_memcmp(buf1 ^void, buf2 ^void, count usize ) int {

    lhs ^uchar = buf1
    rhs ^uchar = buf2

    for(i usize = 0; i < count; i++){
        if(lhs[i] != rhs[i]){
            return (:int)lhs[i] - (:int)rhs[i]
        }
    }
    return 0
   // return memcmp(buf1, buf2, count)
}

pc_memset(b ^void, c int, len usize) ^void {
    i int = 0
    p ^uchar = b
    while(len > 0) {
        *p = c
        p++
        len--
    }
    return b
  //  return memset(b, c, len)
}

pc_isalpha(c int) int {
    
    alphabet[]char = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    letter := alphabet
    while(*letter != 0 && *letter != c){
        ++letter
    }

    if(*letter){
        return 1
    }
    return 0
}

pc_islower(c int) int {
    return c >= 'a' && c <= 'z' ? true : false
}

pc_isprint(c int) int {
    return c >= 0x20 && c <= 0x7E
}

pc_toupper(c int) int {
   
  return pc_islower(c) ? c - 'a' + 'A' : c
}

pc_isdigit(c int) int {
  return (c >= '0') && (c <= '9')
}

pc_tolower(c int) int {
    if(c >= 'A' && c <= 'Z') {
        return c + 'a' - 'A'
    } else {
        return c
    }
}

pc_isalnum(c int ) int {
    return pc_isalpha(c) || pc_isdigit(c)
}

pc_isspace(c int) int {

    return (c == ' ' || c == '\n' || c == '\t' || c == '\r')
}

@foreign
write(filedes int, buf ^void, offset usize) -> usize;




pc_printf(format ^char, ...) int {

args va_list
//va_start(args, format)
//n uint =  va_arg(args, uint)
return 9
}

pc_printf_test(){

    pc_printf("Hello Printf\n", "Arg2")
}