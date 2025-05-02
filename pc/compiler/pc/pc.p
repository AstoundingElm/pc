enum { MAX_SEARCH_PATHS = 256 }
static_package_search_paths ^[MAX_SEARCH_PATHS] char
package_search_paths ^^char = static_package_search_paths 
num_package_search_paths int 

add_package_search_path(path ^char) {
    if (flag_verbose) {
        printf("Adding package search path %s\n", path)
    }
    package_search_paths[num_package_search_paths++] = str_intern(path)
}

add_package_search_path_range(start ^char, end ^char) {
    path[PMAX_PATH]char
    len usize = CLAMP_MAX(end - start, PMAX_PATH - 1)
    pc_memcpy(path, start, len)
    path[len] = 0
    add_package_search_path(path)
}

init_package_search_paths() {
    pchome_var := getenv("PCHOME")
    if (!pchome_var) {
        printf("error: Set the environment variable OLDPCHOME to the pc home directory (where system_packages is located)\n")
        exit(1)
    }
    path[PMAX_PATH]char
    path_copy(path, pchome_var)
    path_join(path, "stdlib")
    add_package_search_path(path)
    add_package_search_path(".")
    pcpath_var := getenv("PCPATH")
    if (pcpath_var) {
        start := pcpath_var;
        for (ptr := pcpath_var; ptr^; ptr++) {
            if (*ptr == ';') {
                add_package_search_path_range(start, ptr)
                start = ptr + 1
            }
        }
        if (*start) {
            add_package_search_path(start)
        }
    }
}

init_compiler() {
    init_target()
    init_package_search_paths()
    init_keywords()
    init_builtin_types()
    map_put(&decl_note_names, declare_note_name, (:^void )1)
}

parse_env_vars() {
    x int = 10;
    a ^int = &x;
    a^ = 20;
    pc_printf_test()
    pcos_var ^char = getenv("PCOS")
    if (pcos_var) {
        os := get_os(pcos_var)
        if (os == -1) {
            printf("Unknown target operating system in PCOS environment variable: %s\n", pcos_var)
        } else {
            target_os = os
        }
    }
    pcarch_var := getenv("PCARCH")
    if (pcarch_var) {
        arch: int = get_arch(pcarch_var)
        if (arch == -1) {
            printf("Unknown target architecture in PCARCH environment variable: %s\n", pcarch_var)
        } else {
            target_arch = arch
        }
    }
}

pc_main(argc int, argv ^^char )  uint64 {
    parse_env_vars();

    output_name: ^char = NULL;
    flag_check bool = false;
    add_flag_str("o", &output_name, "file", "Output file (default: out_<main-package>.c)");
    add_flag_enum("os", &target_os, "Target operating system", os_names, NUM_OSES);
    add_flag_enum("arch", &target_arch, "Target machine architecture", arch_names, NUM_ARCHES);
    add_flag_bool("check", &flag_check, "Semantic checking with no code generation");
    add_flag_bool("lazy", &flag_lazy, "Only compile what's reachable from the main package");
    add_flag_bool("notypeinfo", &flag_notypeinfo, "Don't generate any typeinfo tables");
    add_flag_bool("fullgen", &flag_fullgen, "Force full code generation even for non-reachable symbols");
    add_flag_bool("nolinesync", &flag_nolinesync, "Disable #line synchronization between Ion code and generated C code.");
    add_flag_bool("verbose", &flag_verbose, "Extra diagnostic information");
    add_flag_bool("gen_asm", &flag_gen_asm, "Generate assembly");
    program_name: ^char = parse_flags(&argc, &argv);
    if (argc != 1) {
        printf("Usage: %s [flags] <main-package>\n", program_name);
        print_flags_usage();
        return 1;
    }
    package_name: ^char = pc_strdup(argv[0]);
    if (flag_verbose) {
        printf("Target operating system: %s\n", os_names[target_os]);
        printf("Target architecture: %s\n", arch_names[target_arch]);
    }
    init_compiler();
    builtin_package = import_package("builtin");
    if (!builtin_package) {
        //*(: ^int)0 = 0
        printf("error: Failed to compile package 'builtin'.\n");
        return 1;
    }
    builtin_package.external_name = str_intern("");
    enter_package(builtin_package);
    postinit_builtin();
    any_sym: ^Sym = resolve_name(str_intern("any"));
    if (!any_sym || any_sym.kind != SYM_TYPE) {
        printf("error: Any type not defined");
        return 1;
    }
    type_any = any_sym.type;
    leave_package(builtin_package);
    for (ptr: ^char = package_name; ptr^; ptr++) {
        if (*ptr == '.') {
            *ptr = '/';
        }
    }

    printf("main_package\n")
    main_package: ^Package = import_package(package_name);
    if (!main_package) {
        printf("error: Failed to compile package '%s'\n", package_name);
        return 1;
    }

    printf("main\n")
    main_name: ^char = str_intern("main");

    main_sym: ^Sym = get_package_sym(main_package, main_name);
    if (!main_sym) {
        printf("error: No 'main' entry point defined in package '%s'\n", package_name);
        return 1;
    }

    main_sym.external_name = main_name;
    reachable_phase = REACHABLE_NATURAL;
    resolve_sym(main_sym);
    for (i :usize  = 0; i < buf_len(package_list); i++) {
        if (package_list[i].always_reachable) {
            resolve_package_syms(package_list[i]);
        }
    }

    finalize_reachable_syms();
    if (flag_verbose) {
        printf("Reached %d symbols in %d packages from %s/main\n", (:int)buf_len(reachable_syms), (:int)buf_len(package_list), package_name);
    }
    if (!flag_lazy) {
        reachable_phase = REACHABLE_FORCED;
        for (i := 0; i < buf_len(package_list); i++) {
            resolve_package_syms(package_list[i]);
        }
        finalize_reachable_syms();
    }
    printf("Processed %d symbols in %d packages\n", (:int)buf_len(reachable_syms), (:int)buf_len(package_list));
    if (!flag_check) {
        c_path[PMAX_PATH]char;
        if (output_name) {
            path_copy(c_path, output_name);
        } else {
            snprintf(c_path, sizeof(c_path), "out_%s.c", package_name);
        }

        if(flag_gen_asm){
            
            codegen_program()
            asm_code ^char = gen_buf
            gen_buf = NULL


       // if (!write_file(c_path, asm_code, buf_len(asm_code))) {
         //   printf("error: Failed to write file: %s\n", c_path);
           // return 1;
        //}

        } else {
        gen_all();
        c_code ^char = gen_buf
        gen_buf = NULL
        if (!write_file(c_path, c_code, buf_len(c_code))) {
            printf("error: Failed to write file: %s\n", c_path);
            return 1;
        }
    }
        printf("Generated %s\n", c_path);
        printf("Intern: %.2f MB\n", (:float)intern_memory_usage / (1024 * 1024));
        printf("Source: %.2f MB\n", (:float)source_memory_usage / (1024 * 1024));
        printf("AST:    %.2f MB\n", (:float)ast_memory_usage / (1024 * 1024));
        printf("Ratio:  %.2f\n", (:float)(intern_memory_usage + ast_memory_usage) / source_memory_usage);
    }
    return 0;
}