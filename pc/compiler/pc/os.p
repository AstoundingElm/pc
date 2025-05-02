#foreign
_finddata_t struct {

    attrib int
    time_create time_t
    time_access time_t
    time_write time_t
    size usize
    name char[260]
}

const PMAX_PATH = 260

@foreign("path_absolute")
path_absolute(path[PMAX_PATH]char);


@foreign("dir_list_free")
dir_list_free(iter ^ DirListIter);

@foreign("dir__update")
dir__update(iter ^DirListIter, done bool, fileinfo ^_finddata_t);

@foreign("dir_list_next")
dir_list_next(iter ^DirListIter);

@foreign("dir_list")
dir_list(iter ^DirListIter, path ^char);


@foreign("DirListIter")
DirListIter struct{
    valid bool
     error bool 

    base[PMAX_PATH]char
    name[PMAX_PATH]char 
    size usize
     is_dir bool

    handle ^void
} 

/*
path_absolute(path[MAX_PATH]char) {
    rel_path[MAX_PATH]char;
    path_copy(rel_path, path);
    _fullpath(path, rel_path, MAX_PATH);
}

dir_list_free(iter ^DirListIter) {
    if (iter.valid) {
        _findclose((:intptr)iter.handle);
        iter.valid = false;
        iter.error = false;
    }
}

dir__update(iter ^DirListIter, done bool,  fileinfo  struct  _finddata_t * ) {
    iter.valid = !done;
    iter.error = done && errno != ENOENT;
    if (!done) {
        iter.size = fileinfo.size;
        memcpy(iter.name, fileinfo.name, sizeof(iter.name) - 1);
        iter.name[MAX_PATH - 1] = 0;
        iter.is_dir = fileinfo.attrib & _A_SUBDIR;
    }
}

dir_list_next(iter ^DirListIter) {
    if (!iter.valid) {
        return;
    }
    do {
        fileinfo _finddata_t ;
        result := _findnext((:intptr)iter.handle, &fileinfo);
        dir__update(iter, result != 0, &fileinfo);
        if (result != 0) {
            dir_list_free(iter);
            return;
        }
    } while (dir_excluded(iter));
}

 dir_list(iter ^DirListIter , path ^char) {
    memset(iter, 0, sizeof(*iter));
    path_copy(iter.base, path);
    filespec[MAX_PATH] char 
    path_copy(filespec, path);
    path_join(filespec, "*");
    fileinfo struct _finddata_t
    handle := _findfirst(filespec, &fileinfo);
    iter.handle = (: ^void)handle;
    dir__update(iter, handle == -1, &fileinfo);
    if (dir_excluded(iter)) {
        dir_list_next(iter);
    }
}*/



path_normalize(path ^char) {
    ptr ^char
    for (ptr = path; ptr^; ptr++) {
        if (*ptr == '\\') {
            *ptr = '/'
        }
    }
    if (ptr != path && ptr[-1] == '/') {
        index usize = -1;
        ptr[index] = 0;
    }
}

path_copy(path[PMAX_PATH]char, src ^char) {
    pc_strncpy(path, src, PMAX_PATH)
    path[PMAX_PATH - 1] = 0
    path_normalize(path)
}

path_join(path[PMAX_PATH]char, src ^char) {
    ptr ^char = path + pc_strlen(path)
    if (ptr != path && ptr[-1] == '/') {
        ptr--
    }
    if (*src == '/') {
        src++
    }
    snprintf(ptr, path + PMAX_PATH - ptr, "/%s", src)
}

path_file(path[PMAX_PATH]char) ^char {
    path_normalize(path)
    for (ptr ^char = path + pc_strlen(path); ptr != path; ptr--) {
        if (ptr[-1] == '/') {
            return ptr
        }
    }
    return path
}

path_ext(path[PMAX_PATH]char) ^char {
    for (ptr ^char = path + pc_strlen(path); ptr != path; ptr--) {
        if (ptr[-1] == '.') {
            return ptr
        }
    }
    return path
}

dir_excluded(iter ^DirListIter) bool {
    return iter.valid && (pc_strcmp(iter.name, ".") == 0 || pc_strcmp(iter.name, "..") == 0)
}




/*
#ifdef _WIN32
#include "os_win32.c"
#define strdup _strdup
#else
#include "os_unix.c"
#endif*/

dir_list_subdir(iter ^DirListIter) bool {
    if (!iter.valid || !iter.is_dir) {
        return false
    }
    subdir_iter DirListIter
    path_join(iter.base, iter.name)
    dir_list(&subdir_iter, iter.base)
    dir_list_free(iter);
    iter^ = subdir_iter
    return true
}

dir_list_buf(filespec ^char) ^^char{
    buf ^^char = NULL
    iter DirListIter 
    for (dir_list(&iter, filespec); iter.valid; dir_list_next(&iter)) {
        name ^char = pc_strdup(iter.name)
        buf_push(buf, name)
    }
    return buf
}


// Command line flag parsing

FlagKind enum {
    FLAG_BOOL,
    FLAG_STR,
    FLAG_ENUM,
}

FlagDef struct {
    kind FlagKind 
    name ^char
    help ^char
    options ^^char
    arg_name ^char
    num_options int
    ptr struct {
        i ^int
        b ^bool
        s ^^char
    } 
} 

flag_defs ^FlagDef

add_flag_bool(name ^char, ptr ^bool, help ^char) {
    //buf_push(flag_defs, (:FlagDef){kind = FLAG_BOOL, name = name, help = help, ptr.b = ptr})

   flag_def FlagDef    
    flag_def.kind = FLAG_BOOL  
    flag_def.name = name   
    flag_def.help = help  
    flag_def.ptr.b = ptr
    buf_push(flag_defs, flag_def);
}

add_flag_str(name ^char, ptr ^^char, arg_name ^char, help ^char) {
    flag_def FlagDef    
    flag_def.kind = FLAG_STR    
    flag_def.name = name   
    flag_def.help = help  
    flag_def.arg_name = arg_name
    flag_def.ptr.s = ptr  
    buf_push(flag_defs, flag_def);

//  buf_push(flag_defs, (:FlagDef){kind = FLAG_STR, name = name, help = help, arg_name = arg_name, ptr.s = ptr})
}

add_flag_enum(name ^char, ptr ^int, help ^char, options ^^char, num_options int) {
    flag_def FlagDef    
    flag_def.kind = FLAG_ENUM  
    flag_def.name = name   
    flag_def.help = help  
    flag_def.ptr.i = ptr 
    flag_def.options = options
    flag_def.num_options = num_options
    buf_push(flag_defs, flag_def);
  //  buf_push(flag_defs, (:FlagDef){kind = FLAG_ENUM, name = name, help = help, flagdef_ptr.i = ptr, options = options, num_options = num_options})
}

get_flag_def(name ^char) ^FlagDef {
    for (i usize = 0; i < buf_len(flag_defs); i++) {
        if (pc_strcmp(flag_defs[i].name, name) == 0) {
            return &flag_defs[i]
        }
    }
    return NULL
}

print_flags_usage() {
    printf("Flags:\n")
    for (i usize = 0; i < buf_len(flag_defs); i++) {
        flag := flag_defs[i]
        note[256]char = {0}
        format[256]char
        switch (flag.kind) {
        case FLAG_STR:
            snprintf(format, sizeof(format), "%s <%s>", flag.name, flag.arg_name ? flag.arg_name : "value")
            if (*flag.ptr.s) {
                snprintf(note, sizeof(note), "(default: %s)", *flag.ptr.s)
            }
        case FLAG_ENUM: {
            end := format + sizeof(format)
            ptr := format
            ptr += snprintf(ptr, end - ptr, "%s <", flag.name)
            for (k := 0; k < flag.num_options; k++) {
                ptr += snprintf(ptr, end - ptr, "%s%s", k == 0 ? "" : "|", flag.options[k])
                if (k == *flag.ptr.i) {
                    snprintf(note, sizeof(note), " (default: %s)", flag.options[k])
                }
            }
            snprintf(ptr, end - ptr, ">")
        }
        case FLAG_BOOL:
        default:
            snprintf(format, sizeof(format), "%s", flag.name)
        }
        printf(" -%-32s %s%s\n", format, flag.help ? flag.help : "", note)
    }
}

parse_flags(argc_ptr ^int, argv_ptr ^^^char) ^char {
    argc := *argc_ptr
    argv := *argv_ptr
    i int
    for (i = 1; i < argc; i++) {
        arg ^char = argv[i]
        name ^char = arg
        if (*name== '-') {
            name++
            if (*name== '-') {
                name++
            }
            flag := get_flag_def(name)
            if (!flag) {
                printf("Unknown flag %s\n", arg)
                continue
            }
            switch (flag.kind) {
            case FLAG_BOOL:
                *flag.ptr.b = true
            case FLAG_STR:
                if (i + 1 < argc) {
                    i++;
                    *flag.ptr.s = argv[i]
                } else {
                    printf("No value argument after -%s\n", arg)
                }
            case FLAG_ENUM: {
                option ^char
                if (i + 1 < argc) {
                    i++
                    option = argv[i]
                } else {
                    printf("No value after %s\n", arg)
                    break
                }
                found := false;
                for (k int = 0; k < flag.num_options; k++) {
                    if (pc_strcmp(flag.options[k], option) == 0) {
                        *flag.ptr.i = k
                        found = true
                        break
                    }
                }
                if (!found) {
                    printf("Invalid value '%s' for %s\n", option, arg)
                }
            }
            default:
                printf("Unhandled flag kind\n")
            }
        } else {
            break
        }
    }
    argc_ptr^ = argc - i;
    argv_ptr^ = argv + i;
    return path_file(pc_strdup(argv[0]))
}
