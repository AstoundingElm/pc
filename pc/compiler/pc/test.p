
intern_test fn() {
    arrtest []char = "hello"
    #assert(pc_strcmp(arrtest, str_intern(arrtest)) == 0)
    #assert(str_intern(arrtest) == str_intern(arrtest))
    #assert(str_intern(str_intern(arrtest)) == str_intern(arrtest))
    b []char = "hello"
    #assert(arrtest != b)
    #assert(str_intern(arrtest) == str_intern(b))
    c []char = "hello!"
    #assert(str_intern(arrtest) != str_intern(c))
    d []char = "hell"
    #assert(str_intern(arrtest) != str_intern(d))
}

common_test fn() {
    buf_test()
    intern_test()
    map_test()
    printf("Map test completed!\n")
    str1 ^char = strf("%d %d", 1, 2)
    #assert(pc_strcmp(str1, "1 2") == 0)
    str2 ^char  = strf("%s %s", str1, str1)
    #assert(pc_strcmp(str2, "1 2 1 2") == 0)
    str3 ^char = strf("%s asdf %s", str2, str2)
    #assert(pc_strcmp(str3, "1 2 1 2 asdf 1 2 1 2") == 0)

    printf("Common test completed!\n")
}

//name_map Arena

main_test fn() {
    common_test()

    //alloc Allocator
   // alloc.alloc = pc_arena_alloc
    //alloc.free = pc_arena_free
    //lex_test()
    //print_test()
    //parse_test()
  // resolve_test()
    //gen_test()
}

assert_token_int(x int64)
{ 

#assert(token.int_val == x && match_token(TOKEN_INT))

}

assert_token_eof(){ #assert(is_token(0))}

assert_token_float(x double) { 
temp float = token.float_val

#assert(temp == x && match_token(TOKEN_FLOAT))

}

assert_token_str(x ^char ) {

   #assert(pc_strcmp(token.str_val, (x)) == 0 && match_token(TOKEN_STR))

}

assert_token(x TokenKind){ 
    #assert(match_token(x))

}

assert_token_name(x ^char ) {

    #assert(token.name == str_intern(x) && match_token(TOKEN_NAME))

}


 keyword_test() {

    
    init_keywords()
  
    #assert(is_keyword_name(first_keyword))
    #assert(is_keyword_name(last_keyword))
   


    for it :^^char  = keywords, it != buf_end(keywords), it++ {
        #assert(is_keyword_name(*it))
    }

    #assert(!is_keyword_name(str_intern("foo")))
    #assert(is_keyword_name(str_intern("typedef")))
    #assert(is_keyword_name(str_intern("enum")))

}


lex_test()
{

keyword_test()
#assert(str_intern("fn") == fn_keyword)

init_stream(NULL, "0 18446744073709551615 0xffffffffffffffff 042 0b1111")
assert_token_int(0)
   assert_token_int(18446744073709551615ull)

    #assert(token.mod == MOD_HEX)
    assert_token_int(0xffffffffffffffffull)
    #assert(token.mod == MOD_OCT)
    assert_token_int(042)
    #assert(token.mod == MOD_BIN)
    assert_token_int(0xF)
    assert_token_eof()

   init_stream(NULL,"3.14 .123 42. 3e10")

    assert_token_float(3.14)


   assert_token_float(.123)
    assert_token_float(42.)
    assert_token_float(3e10)
    assert_token_eof()

    // Char literal tests
    init_stream(NULL,"'a' '\\n'")
    assert_token_int('a')
    assert_token_int('\n')
    assert_token_eof()

    // String literal tests
    init_stream(NULL,"\"foo\" \"a\\nb\"")
    assert_token_str("foo")
    assert_token_str("a\nb")
    assert_token_eof()

    // Operator tests
    init_stream(NULL,": := + += ++ < <= << <<=")
    assert_token(TOKEN_COLON)

   assert_token(TOKEN_COLON_ASSIGN)

    assert_token(TOKEN_ADD)
    assert_token(TOKEN_ADD_ASSIGN)
    assert_token(TOKEN_INC)
    assert_token(TOKEN_LT)
    assert_token(TOKEN_LTEQ)
    assert_token(TOKEN_LSHIFT)
    assert_token(TOKEN_LSHIFT_ASSIGN)
    assert_token_eof()


    // Misc tests
    init_stream(NULL,"XY+(XY)_HELLO1,234+994")
    assert_token_name("XY")

    assert_token(TOKEN_ADD)
    assert_token(TOKEN_LPAREN)
    assert_token_name("XY")

    assert_token(TOKEN_RPAREN)
    assert_token_name("_HELLO1")
    assert_token(TOKEN_COMMA)

    assert_token_int(234)
    assert_token(TOKEN_ADD)
    assert_token_int(994)
    assert_token_eof()
    printf("Lex test completed!\n")


}


parse_test() 
{

  //"func fact(n: int): int { trace(\"fact\"); if (n == 0) { return 1; } else { return n * fact(n-1); } }",    
    decls : ^[]char = {
      //" x [256]char = {1, 2, 3, ['a'] = 4}",
        "Vector struct { x, y: float }",
        //"v = Vector{x = 1.0, y = -1.0}",
        //"v Vector = {1.0, -1.0}",
        //"n := sizeof(:int*[16])",
        //" n := sizeof(1+2)",
        "x int = b == 1 ? 1+2 : 3-4",
        "fact(n int) int { if (n == 0) { return 1 } else { return n * fact(n-1) } }",
        "fact(n int) int { p := 1 for (i := 1; i <= n; i++) { p = i } return p }", //p *= i
        "foo int = a ? a&b + c<<d + e*f == +u-v-w + *g/h(x,y) + -i%k[x] && m <= n*(p+q)/r : 0",
        "f(x int) bool { switch (x) { case 0: case 1: return true case 2: default: return false } }",
        "Color enum { RED = 3, GREEN, BLUE = 0 }",
        "pi double = 3.14",
        "IntOrFloat union { i int f float }",
        //"typedef Vectors = Vector[1+2]",
        "f() { do {  } while(1) }", //print(42)
        //"typedef T = (func(int):int)[16]",
        "f() {  E enum { A, B, C } return; }",
        "f fn() int { if (1) { return 1 } else if (2) { return 2 } else { return 3 } }",
    }
       
    for (it := decls, it != decls + sizeof(decls)/sizeof(*decls) , it++) {
   
        init_stream(NULL, *it)
      
         decl := parse_decl()

      // print_decl(decl)
    
      printf("\n")  
   }

   printf("Parse test completed!\n")
}

resolve_test() {
/*    int_ptr ^Type = type_ptr(type_int)
    #assert(type_ptr(type_int) == int_ptr)
    
    float_ptr := type_ptr(type_float)
    #assert(type_ptr(type_float) == float_ptr)
    
    #assert(int_ptr != float_ptr)
    int_ptr_ptr := type_ptr(type_ptr(type_int))
    #assert(type_ptr(type_ptr(type_int)) == int_ptr_ptr)

    float4_array := type_array(type_float, 4)
    #assert(type_array(type_float, 4) == float4_array)
    
    float3_array := type_array(type_float, 3)
    #assert(type_array(type_float, 3) == float3_array)
    #assert(float4_array != float3_array)
    
    int_int_func := type_func(&type_int, 1, type_int, false)
    #assert(type_func(&type_int, 1, type_int, false) == int_int_func)
    int_func := type_func(NULL, 0, type_int, false)
    #assert(int_int_func != int_func)
    #assert(int_func == type_func(NULL, 0, type_int, false))
*/
    //init_builtins()

    code : ^[]char = {
        "IntOrPtr union { i int p int* }",
        
        //"u1 = IntOrPtr{i = 42}",
        //"var u2 = IntOrPtr{p = (:int*)42}",
        "i int",
        "Vector struct { x, y: int }",
        //"func f1() { v := Vector{1, 2}; j := i; i++; j++; v.x = 2*j; }",
        "f2(n int) int { return 2*n }",
        "f3(x int) int { if (x) { return -x } else if (x % 2 == 0) { return 42 } else { return -1 } }",
        "f4(n int) int { for (i := 0; i < n; i++) { if (i % 3 == 0) { return n } } return 0 }",
        "f5(x int) int { switch(x) { case 0: case 1: return 42 case 3: default: return -1 } }",
        //"f6(n int) int { p := 1; while (n) { p *= 2; n--; } return p }",
        //"f7(n int) int { p := 1 do { p *= 2 n-- } while (n) return p }",
        
        }

        alt ^[]char = {

        "i int",
        //"add(v Vector, w Vector) Vector { return {v.x + w.x, v.y + w.y} }",
        //"var a: int[256] = {1, 2, ['a'] = 42, [255] = 123}",
       // "v Vector = 0 ? {1,2} : {3,4}",
        //"var vs: Vector[2][2] = {{{1,2},{3,4}}, {{5,6},{7,8}}}",

        "A struct { c char }",
        "B struct { i int }",
        "C struct { c char a A }",
        /*"func print(v: Vector) { printf(\"{%d, %d}\", v.x, v.y); }",
        "var x = add({1,2}, {3,4})",
        "var v: Vector = {1,2}",
        "var w = Vector{3,4}",
        "var p: void*",
        "var i = (:int)p + 1",
        "var fp: func(Vector)",
        "struct Dup { x: int; x: int; }",
        "var a: int[3] = {1,2,3}",
        "var b: int[4]",
        "var p = &a[1]",
        "var i = p[1]",
        "var j = *p",
        "const n = sizeof(a)",
        "const m = sizeof(&a[0])",
        "const l = sizeof(1 ? a : b)",
        "var pi = 3.14",
        "var name = \"Per\"",
        "var v = Vector{1,2}",
        "var j = (:int)p",
        "var q = (:int*)j",
        "const i = 42",
        "const j = +i",
        "const k = -i",
        "const a = 1000/((2*3-5) << 1)",
        "const b = !0",
        "const c = ~100 + 1 == -100",
        "const k = 1 ? 2 : 3",
        "union IntOrPtr { i: int; p: int*; }",
        "var i = 42",
        "var u = IntOrPtr{i, &i}",
        "const n = 1+sizeof(p)",
        "var p: T*",
        "var u = *p",
        "struct T { a: int[n]; }",
        "var r = &t.a",
        "var t: T",
        "typedef S = int[n+m]",
        "const m = sizeof(t.a)",
        "var i = n+m",
        "var q = &i",
        "const n = sizeof(x)",
        "var x: T",
        "struct T { s: S*; }",
        "struct S { t: T[n]; }",*/

        }


      for (i usize = 0; i < sizeof(code)/sizeof(*code); i++) {
        init_stream(NULL, code[i])
        decl := parse_decl()
        sym_global_decl(decl)
    }

    for (i usize = 0; i < sizeof(alt)/sizeof(*alt); i++) {
        init_stream(NULL, alt[i])
        decl := parse_decl()
        sym_global_decl(decl)
    }

   // finalize_syms()
   /* for (it := ordered_syms; it != buf_end(ordered_syms); it++) {
        sym := *it
        if (sym.decl) {
            print_decl(sym.decl)
        } else {
            printf("%s", sym.name)
        }
        printf("\n")
    }
*/

printf("Resolve test completed!\n")
  }