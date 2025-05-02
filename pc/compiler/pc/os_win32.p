


/*
path_absolute(path[MAX_PATH]char) {
    rel_path[MAX_PATH]char;
    path_copy(rel_path, path);
    _fullpath(path, rel_path, MAX_PATH);
}

dir_list_free(iter ^DirListIter) {
    if (iter.valid) {
        _findclose((:intptr)iter.handle)
        iter.valid = false;
        iter.error = false;
    }
}

dir__update(iter ^DirListIter, done bool, fileinfo ^_finddata_t) {
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
        fileinfo _finddata_t;
        result := _findnext((:intptr)iter.handle, &fileinfo);
        dir__update(iter, result != 0, &fileinfo);
        if (result != 0) {
            dir_list_free(iter);
            return;
        }
    } while (dir_excluded(iter));
}

dir_list(iter ^DirListIter, path ^char) {
    memset(iter, 0, sizeof(*iter));
    path_copy(iter.base, path);
    filespec[MAX_PATH]char;
    path_copy(filespec, path);
    path_join(filespec, "*");
    dfileinfo: _finddata_t;
    handle intptr = _findfirst(filespec, &dfileinfo);
    iter.handle = (: ^void)handle;
    dir__update(iter, handle == -1, &dfileinfo);
    if (dir_excluded(iter)) {
        dir_list_next(iter);
    }
}*/
