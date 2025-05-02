/*#foreign(header = "<IO.h>")

@foreign const _A_SUBDIR = 0x10;

#foreign(preamble = "typedef struct _finddata64i32_t _finddata_t;")

typedef _fsize_t = ulong;

_finddata_t struct {

	attrib uint
	time_create time_t
	time_access time_t
	time_write time_t 
	size _fsize_t  
	name[256]char
}

@foreign("_findfirst")
_findfirst(filespec ^char, fileinfo ^_finddata_t) -> intptr;

@foreign("_findnext")
_findnext(handle intptr, fileinfo ^_finddata_t) -> int;

@foreign("_findclose")
_findclose(hand intptr) -> int;

@foreign("_fullpath")
_fullpath(absPath ^char, relPath ^char, maxLength usize) -> ^char;*/