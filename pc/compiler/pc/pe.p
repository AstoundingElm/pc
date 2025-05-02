/*
typedef u8 = uchar 
typedef pu8 = uchar *
typedef  u16 = ushort 
typedef pu16 = ushort *
typedef  u32 = uint
typedef  pu32 = uint*
typedef  u64 = ullong 
typedef pu64 = ullong *
typedef s8 = char
typedef ps8 = char *
typedef  s16 = short 
typedef ps16 = short *
typedef s32 = long *
typedef ps32 = long *
typedef  s64 = llong
typedef ps64 = llong *
typedef pvoid = void *

const IMAGE_NT_SIGNATURE                 = 0x00004550
const IMAGE_NT_OPTIONAL_HDR32_MAGIC      = 0x10b
const IMAGE_FILE_MACHINE_I386            = 0x014c
const IMAGE_NUMBEROF_DIRECTORY_ENTRIES   = 16
const IMAGE_SUBSYSTEM_WINDOWS_CUI        = 3
const IMAGE_DIRECTORY_ENTRY_IMPORT       = 1
const IMAGE_FILE_EXECUTABLE_IMAGE        = 0x0002
const IMAGE_FILE_32BIT_MACHINE           = 0x0100
const IMAGE_SCN_MEM_EXECUTE              = 0x20000000
const IMAGE_SCN_MEM_READ                 = 0x40000000
const IMAGE_SCN_MEM_WRITE                = 0x80000000
const IMAGE_SIZEOF_SHORT_NAME            = 8

IMAGE_FILE_HEADER struct {
    Machine u16 
    NumberOfSections u16
    TimeDateStamp u32 
    PointerToSymbolTable u32 
    NumberOfSymbols u32 
    SizeOfOptionalHeader u16 
    Characteristics u16 
} 

typedef PIMAGE_FILE_HEADER = IMAGE_FILE_HEADER *

IMAGE_DATA_DIRECTORY struct  {
    VirtualAddress u32
    Size u32
}  

typedef PIMAGE_DATA_DIRECTORY = IMAGE_DATA_DIRECTORY*

IMAGE_OPTIONAL_HEADER32 struct  {
    Magic u16 
    MajorLinkerVersion u8 
    MinorLinkerVersion u8 
    SizeOfCode u32
    SizeOfInitializedData u32
    SizeOfUninitializedData u32
    AddressOfEntryPoint u32
    BaseOfCode u32
    BaseOfData u32

    ImageBase u32
    SectionAlignment u32
    FileAlignment u32
    MajorOperatingSystemVersion u16 
    MinorOperatingSystemVersion u16 
    MajorImageVersion u16 
    MinorImageVersion u16 
    MajorSubsystemVersion u16 
    MinorSubsystemVersion u16 
    Win32VersionValue u32 
    SizeOfImage u32 
    SizeOfHeaders u32 
    CheckSum u32 
    Subsystem u16 
    DllCharacteristics u16 
    SizeOfStackReserve u32 
    SizeOfStackCommit u32 
    SizeOfHeapReserve u32 
    SizeOfHeapCommit u32 
    LoaderFlags u32 
    NumberOfRvaAndSizes u32 
    DataDirectory[IMAGE_NUMBEROF_DIRECTORY_ENTRIES] IMAGE_DATA_DIRECTORY 
} 

typedef PIMAGE_OPTIONAL_HEADER32 = IMAGE_OPTIONAL_HEADER32 *

IMAGE_SECTION_HEADER struct  {
     Name[IMAGE_SIZEOF_SHORT_NAME] s8
    union {
        PhysicalAddress u32 
        VirtualSize u32 
    } //Misc;
    VirtualAddress u32
    SizeOfRawData u32
    PointerToRawData u32
    PointerToRelocations u32
    PointerToLinenumbers u32
    NumberOfRelocations u16
    NumberOfLinenumbers u16
    Characteristics u32
} 

typedef PIMAGE_SECTION_HEADER = IMAGE_SECTION_HEADER *

IMAGE_IMPORT_BY_NAME struct  {
    Hint u16 
    Name[1] s8 
} 

typedef PIMAGE_IMPORT_BY_NAME = IMAGE_IMPORT_BY_NAME

IMAGE_THUNK_DATA32 struct  {
    union {
        ForwarderString u32 
        Function u32 
        Ordinal u32 
        AddressOfData u32 
    }
} 
typedef  PIMAGE_THUNK_DATA32 = IMAGE_THUNK_DATA32 *

IMAGE_IMPORT_DESCRIPTOR struct  {
    union {
         Characteristics u32
         OriginalFirstThunk u32
    } 
     TimeDateStamp u32
     ForwarderChain u32
     Name u32
    FirstThunk u32
} 
typedef   PIMAGE_IMPORT_DESCRIPTOR  = IMAGE_IMPORT_DESCRIPTOR *

dos_hdr[128]uchar = {
    0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00,
    0xB8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00,
    0x0E, 0x1F, 0xBA, 0x0E, 0x00, 0xB4, 0x09, 0xCD, 0x21, 0xB8, 0x01, 0x4C, 0xCD, 0x21, 0x54, 0x68,
    0x69, 0x73, 0x20, 0x70, 0x72, 0x6F, 0x67, 0x72, 0x61, 0x6D, 0x20, 0x63, 0x61, 0x6E, 0x6E, 0x6F,
    0x74, 0x20, 0x62, 0x65, 0x20, 0x72, 0x75, 0x6E, 0x20, 0x69, 0x6E, 0x20, 0x44, 0x4F, 0x53, 0x20,
    0x6D, 0x6F, 0x64, 0x65, 0x2E, 0x0D, 0x0D, 0x0A, 0x24, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
}

const CEED_FILE_ALIGN =                 0x200           // 512B
const CEED_SECTION_ALIGN =              0x100000        // 16MB
const CEED_IMAGE_BASE_VA =              0x400000
const CEED_IMPORT_SECTION_RVA =         (CEED_SECTION_ALIGN * 1)
const CEED_DATA_SECTION_RVA =           (CEED_SECTION_ALIGN * 2)
const CEED_CODE_SECTION_RVA =           (CEED_SECTION_ALIGN * 3)
const CEED_RDATA_SECTION_RVA =          (CEED_SECTION_ALIGN * 4)

const CEED_STDIN_HANDLE_RVA =           0x800
const CEED_STDOUT_HANDLE_RVA =          0x804
const CEED_TEMP_U32_1 =                 0xf00


k32_fn_array u32
fn_GetStdHandle u32
fn_ReadConsoleA u32
fn_WriteConsoleA u32

section_info struct
{
    scn_hdr IMAGE_SECTION_HEADER
    scn_data pu8 
    scn_size u32 
    scn_file_size u32
    scn_file_offset u32 
    scn_virtual_size u32 
} 



typedef psection_info = section_info *

exe_info struct
{
    import_scn psection_info 
    data_scn psection_info 
    code_scn psection_info 
    rdata_scn psection_info

    fh IMAGE_FILE_HEADER 
    oh IMAGE_OPTIONAL_HEADER32
    scn_count u32 
    scn_list [8]psection_info 
}  

typedef pexe_info = exe_info *


ei ^void

 
pe_new_section(ei pexe_info, name ^char, scn_va u32, attr u32 ) psection_info
{
    si psection_info  = malloc(sizeof(section_info));
    pc_memset(si, 0, sizeof(section_info));
    pc_strcpy(si.scn_hdr.Name, name);
    si.scn_hdr.Characteristics = attr;
    si.scn_hdr.VirtualAddress = scn_va;
    ei.scn_list[ei.scn_count++] = si;
    return si;
}


pe_alloc_exe_info() ^void
{
    ei pexe_info  = malloc(sizeof(exe_info));
    pc_memset(ei, 0, sizeof(exe_info));

    ei.import_scn = pe_new_section(ei, ".idata", CEED_IMPORT_SECTION_RVA,
                                    IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_WRITE);

    ei.data_scn = pe_new_section(ei, ".data", CEED_DATA_SECTION_RVA,
                                  IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_WRITE);

    ei.code_scn = pe_new_section(ei, ".text", CEED_CODE_SECTION_RVA,
                                  IMAGE_SCN_MEM_EXECUTE | IMAGE_SCN_MEM_READ);

    ei.rdata_scn = pe_new_section(ei, ".rdata", CEED_RDATA_SECTION_RVA,
                                   IMAGE_SCN_MEM_READ);

    return ei;
}


round_up(n u32, r u32) u32 { return ((((n) + ((r)-1))/(r))*(r))}

pe_set_scn(si psection_info, scn_data pu8, scn_size u32) pvoid
{
    si.scn_data = scn_data;
    si.scn_size = scn_size;
    si.scn_virtual_size = scn_size;
    si.scn_file_size = round_up(scn_size, CEED_FILE_ALIGN);

    si.scn_hdr.VirtualSize = si.scn_virtual_size;
    si.scn_hdr.SizeOfRawData = si.scn_file_size;
    return NULL;
}


pe_set_exe_code_scn(einfo pvoid, scn_data pu8, scn_size u32) pvoid
{
    ei pexe_info = einfo;
    return pe_set_scn(ei.code_scn, scn_data, scn_size);
}


pe_set_exe_data_scn(einfo pvoid , scn_data pu8, scn_size u32) pvoid
{
    ei pexe_info = einfo
    return pe_set_scn(ei.data_scn, scn_data, scn_size);
}


pe_set_exe_rdata_scn(einfo pvoid, scn_data pu8, scn_size u32) pvoid
{
    ei pexe_info = einfo;
    return pe_set_scn(ei.rdata_scn, scn_data, scn_size);
}


pe_set_exe_import_scn(einfo pvoid, scn_data pu8, scn_size u32) pvoid
{
    ei pexe_info = einfo;
    return pe_set_scn(ei.import_scn, scn_data, scn_size);
}


pe_get_code_va(einfo pvoid) u32
{
    return CEED_IMAGE_BASE_VA + CEED_CODE_SECTION_RVA;
}


pe_get_data_va(einfo pvoid ) u32
{
    return CEED_IMAGE_BASE_VA + CEED_DATA_SECTION_RVA;
}


pe_get_rdata_va(einfo pvoid ) u32
{
    return CEED_IMAGE_BASE_VA + CEED_RDATA_SECTION_RVA;
}

const MAX_FUNCTIONS_IMPORT_PER_DLL  =  8
//#define c_assert(e) typedef char __c_assert__[(e)?1:-1]

import_buffer[4096] u8

pe_gen_import_section(ei pexe_info)
{
    _import pu8  = import_buffer;
    iid ^IMAGE_IMPORT_DESCRIPTOR
    th ^IMAGE_THUNK_DATA32 
    oth ^IMAGE_THUNK_DATA32 
    iin ^IMAGE_IMPORT_BY_NAME 
    dll_names ^[]char = { "kernel32.dll", "ntdll.dll" };
    fn_names char * [13][10]   = {
            { "WriteConsoleA", "ReadConsoleA", "GetStdHandle", 0 },
            { "NtReadFile", 0 },
    };

    dll_count := sizeof(dll_names) / sizeof(dll_names[0]);

    //#assert((sizeof(dll_names) / sizeof(dll_names[0])) == 
      //       (sizeof(fn_names) / sizeof(fn_names[0])));

    //
    // Add +1 in dll_count to add a NULL entry as dll import array is NULL
    // terminated.
    //
    offset u32 = (dll_count + 1) * sizeof(IMAGE_IMPORT_DESCRIPTOR);

    iid = (: ^IMAGE_IMPORT_DESCRIPTOR )_import;

    for (i int  = 0; i < dll_count; i++) {
        thunk_count u32  = 0;
        name pu8  = _import + offset;
        th_size u32 

        iid[i].Name = offset + CEED_IMPORT_SECTION_RVA;
        pc_strcpy((:^char)name, dll_names[i]);
        offset += pc_strlen((:^char)name) + 1;

        for (j int  = 0; j < MAX_FUNCTIONS_IMPORT_PER_DLL; j++) {
            if (fn_names[i][j] == NULL) {
                break;
            }
            thunk_count++;
        }

        //
        // Add +1 in thunk_count to add a NULL entry as thunk array is NULL
        // terminated.
        //
        th_size = (thunk_count + 1) * sizeof(IMAGE_THUNK_DATA32);
        iid[i].OriginalFirstThunk = offset + CEED_IMPORT_SECTION_RVA;
        iid[i].FirstThunk = offset + th_size + CEED_IMPORT_SECTION_RVA;
        if (pc_strcmp(dll_names[i], "kernel32.dll") == 0) {
            k32_fn_array = iid[i].FirstThunk + CEED_IMAGE_BASE_VA;
        }
        oth = (: ^IMAGE_THUNK_DATA32)(_import + offset);
        th = (: ^IMAGE_THUNK_DATA32 )(_import + offset + th_size);
        offset += (2 * th_size);

        for (j int = 0; j < MAX_FUNCTIONS_IMPORT_PER_DLL; j++) {
            if (fn_names[i][j] == NULL) {
                break;
            }

            if (pc_strcmp(fn_names[i][j], "GetStdHandle") == 0) {
                fn_GetStdHandle = k32_fn_array + (sizeof(u32) * j);
            } else if (pc_strcmp(fn_names[i][j], "ReadConsoleA") == 0) {
                fn_ReadConsoleA = k32_fn_array + (sizeof(u32) * j);
            } else if (pc_strcmp(fn_names[i][j], "WriteConsoleA") == 0) {
                fn_WriteConsoleA = k32_fn_array + (sizeof(u32) * j);
            }

            oth[j].AddressOfData = offset + CEED_IMPORT_SECTION_RVA;
            th[j].AddressOfData = oth[j].AddressOfData;

            iin = (:pvoid)(_import + offset);
            pc_strcpy((: ^char)iin.Name, fn_names[i][j]);
            offset += (offsetof(IMAGE_IMPORT_BY_NAME, Name) + 
                       pc_strlen(iin.Name) + 1);
        }
    }
    pe_set_exe_import_scn(ei, _import, offset);
}

typedef pfn_gen_exe_file = func( ei :pvoid  ): void;
typedef pfn_set_exe_scn = func(ei :pvoid , scn_data  :pu8, scn_size :u32) :pvoid
typedef pfn_get_va = func(ei :pvoid ) :u32;
typedef pfn_emit_main_init = func() :void;
typedef pfn_emit_main_exit = func () :void
typedef pfn_emit_write = func(buf_addr :u32, buf_len: u32) : void;
typedef pfn_emit_write_reg_input = func() : void;
typedef pfn_emit_read = func(buf_addr: u32, buf_len: u32) :void;


gen_exe_file pfn_gen_exe_file
set_exe_code_scn pfn_set_exe_scn
set_exe_rdata_scn pfn_set_exe_scn
get_code_va pfn_get_va
get_data_va pfn_get_va
get_rdata_va pfn_get_va
emit_main_init pfn_emit_main_init
emit_main_exit pfn_emit_main_exit
emit_write pfn_emit_write
emit_write_reg_input pfn_emit_write_reg_input
emit_read pfn_emit_read

_func[26] int
pe_gen_exe_file(einfo pvoid )
{
    ei pexe_info  = einfo;
    exe_file ^FILE 
    hdr_size u32 
    file_offset u32

    if (_func[0] == -1)
    {
        printf("Entry point function '_a' not found.\n");
        exit(-1);
    }

    exe_file = fopen("a.exe", "wb+");
    if (exe_file == NULL)
    {
        printf("Failed to create output file (a.exe).\n");
        exit(errno);
    }

    pe_gen_data_section(ei);
    pe_write_fixed_hdrs(ei, exe_file);
    pe_write_optional_hdr(ei, exe_file);
    hdr_size = sizeof(dos_hdr) + sizeof(u32) + sizeof(IMAGE_FILE_HEADER) + 
               sizeof(IMAGE_OPTIONAL_HEADER32) + 
               (sizeof(IMAGE_SECTION_HEADER) * ei.scn_count);
    file_offset = round_up(hdr_size, CEED_FILE_ALIGN);
    for (i int = 0; i < ei.scn_count; i++)
    {
        si psection_info  = ei.scn_list[i];
        si.scn_hdr.PointerToRawData = file_offset;
        pe_write_section_hdr(si, exe_file);
        file_offset += si.scn_file_size;
    }
    file_offset = round_up(hdr_size, CEED_FILE_ALIGN);
    for (i int  = 0; i < ei.scn_count; i++)
    {
        si psection_info  = ei.scn_list[i];
        pe_write_section_data(si, file_offset, exe_file);
        file_offset += si.scn_file_size;
    }

    fclose(exe_file);
}

const CEED_MAX_CODE_SIZE =      0x100000        // 1MB
const CEED_MAX_RDATA_SIZE =     0x100000        // 1MB
 code_pos  u32 = 0
 code pu8
 rdata_pos u32 = 0
rdata pu8 
 itoa_code[] u8
atoi_code[] u8

 
gen_exe()
{
    set_exe_code_scn(ei, code, code_pos);
    set_exe_rdata_scn(ei, rdata, rdata_pos);
    gen_exe_file(ei);
}

pe_init(){

    ei = pe_alloc_exe_info()
    pe_gen_import_section(ei);
    gen_exe_file = pe_gen_exe_file;
    set_exe_code_scn = pe_set_exe_code_scn;
    set_exe_rdata_scn = pe_set_exe_rdata_scn;
    get_code_va = pe_get_code_va;
    get_data_va = pe_get_data_va;
    get_rdata_va = pe_get_rdata_va;
    emit_main_exit = pe_emit_main_exit;
    emit_main_init = pe_emit_main_init;
    emit_write = pe_emit_write;
    emit_write_reg_input = pe_emit_write_reg_input;
    emit_read = pe_emit_read;
}

data_buffer[4096] u8 
const CEED_MAX_VARIABLES  = 26

pe_gen_data_section( ei pexe_info)
{
    //
    // Only 26 global variables of 4-byte int size are supported.
    //
    pe_set_exe_data_scn(ei, data_buffer, (CEED_MAX_VARIABLES * 4)); 
}


pe_write_fixed_hdrs( ei pexe_info, file ^ FILE)
{
     nt_sig u32 = IMAGE_NT_SIGNATURE;
     fh IMAGE_FILE_HEADER = { 0 };

    fh.Machine = IMAGE_FILE_MACHINE_I386;
    fh.NumberOfSections = ei.scn_count;
    fh.TimeDateStamp = 0;
    fh.PointerToSymbolTable = 0;
    fh.NumberOfSymbols = 0;
    fh.SizeOfOptionalHeader = sizeof(IMAGE_OPTIONAL_HEADER32);
    fh.Characteristics = (IMAGE_FILE_EXECUTABLE_IMAGE | IMAGE_FILE_32BIT_MACHINE);

    fwrite(dos_hdr, sizeof(dos_hdr), 1, file);
    fwrite(&nt_sig, sizeof(nt_sig), 1, file);
    fwrite(&fh, sizeof(fh), 1, file);
}


pe_write_optional_hdr(ei pexe_info , file ^FILE)
{
    oh IMAGE_OPTIONAL_HEADER32  = { 0 };
     hdr_size u32

    oh.Magic = IMAGE_NT_OPTIONAL_HDR32_MAGIC;
    oh.MajorLinkerVersion = 0;
    oh.MinorLinkerVersion = 1;
    oh.SizeOfCode = 8;
    oh.SizeOfInitializedData = 0;
    oh.SizeOfUninitializedData = 0;
    oh.AddressOfEntryPoint = 0;                     // Fixed later.
    oh.BaseOfCode = 0;                              // Fixed later.
    oh.ImageBase = 0x400000;
    oh.SectionAlignment = CEED_SECTION_ALIGN;
    oh.FileAlignment = CEED_FILE_ALIGN;
    oh.MajorOperatingSystemVersion = 4;
    oh.MinorOperatingSystemVersion = 0;
    oh.MajorImageVersion = 0;
    oh.MinorImageVersion = 0;
    oh.MajorSubsystemVersion = 4;
    oh.MinorSubsystemVersion = 0;
    oh.Win32VersionValue = 0;
    oh.SizeOfImage = 0;                             // Fixed later.
    oh.SizeOfHeaders = 0;                           // Fixed later.
    oh.CheckSum = 0x1D68;
    oh.Subsystem = IMAGE_SUBSYSTEM_WINDOWS_CUI;
    oh.DllCharacteristics = 0;
    oh.SizeOfStackReserve = 0x100000;
    oh.SizeOfStackCommit = 0x1000;
    oh.SizeOfHeapReserve = 0x100000;
    oh.SizeOfHeapCommit = 0x1000;
    oh.LoaderFlags = 0;
    oh.NumberOfRvaAndSizes = 16;
    // Leave all DataDirectory as 0.

    oh.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress = CEED_IMPORT_SECTION_RVA;
    oh.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].Size = ei.import_scn.scn_file_size;
   
    oh.AddressOfEntryPoint = CEED_CODE_SECTION_RVA + _func[0];
    oh.BaseOfCode = CEED_CODE_SECTION_RVA;

    //
    // This needs to be calculated to be the actual size in memory of the
    // image. So all section's virtual size.
    //
    hdr_size = sizeof(dos_hdr) + sizeof(u32) + sizeof(IMAGE_FILE_HEADER) + 
               sizeof(IMAGE_OPTIONAL_HEADER32) + 
               (sizeof(IMAGE_SECTION_HEADER) * ei.scn_count);
    oh.SizeOfImage = round_up(hdr_size, CEED_SECTION_ALIGN);
    for (i int = 0; i < ei.scn_count; i++)
    {
        oh.SizeOfImage += round_up(ei.scn_list[i].scn_virtual_size,
                                   CEED_SECTION_ALIGN);
    }
    oh.SizeOfHeaders = hdr_size;

    fwrite(&oh, sizeof(oh), 1, file);
}


pe_write_section_hdr(si psection_info, file ^FILE)
{
    fwrite(&si.scn_hdr, sizeof(si.scn_hdr), 1, file);
}


pe_write_section_data(si psection_info, file_offset u32, file ^FILE)
{
    fseek(file, file_offset, SEEK_SET);
    fwrite(si.scn_data, si.scn_file_size, 1, file);
}

const STD_INPUT_HANDLE    = (-10)
const STD_OUTPUT_HANDLE   = (-11)


pe_emit_main_init()
{
    //
    // We use this to invoke some code from main that stores handles to stdin
    // and stdout in global variable.
    //
    pe_emit_get_std_handle(STD_INPUT_HANDLE, CEED_STDIN_HANDLE_RVA);
    pe_emit_get_std_handle(STD_OUTPUT_HANDLE, CEED_STDOUT_HANDLE_RVA);

}


pe_emit_main_exit()
{
    // ret
    emit8(0xc3);
}


pe_emit_write( buf_addr u32,  buf_len u32)
{
    //
    // Uses WriteConsole win32 API.
    //

    // push 0 (lpReserved -> NULL)
    emit16(0x006a);

    // push temp location (lpNumberOfCharsWritten)
    emit8(0x68);
    emit32(get_data_va(ei) + CEED_TEMP_U32_1);

    // push buf_len (nNumberOfCharsToWrite)
    emit8(0x68);
    emit32(buf_len);

    // push buf_addr (lpBuffer)
    emit8(0x68);
    emit32(buf_addr);

    // push stdout handle from saved location
    emit16(0x35ff);
    emit32(get_data_va(ei) + CEED_STDOUT_HANDLE_RVA);

    // call [fn_addr]
    emit16(0x15ff);
    emit32(fn_WriteConsoleA);
}


pe_emit_write_reg_input()
{
    //
    // Uses WriteConsole win32 API.
    //

    // push 0 (lpReserved -> NULL)
    emit16(0x006a);

    // push temp location (lpNumberOfCharsWritten)
    emit8(0x68);
    emit32(get_data_va(ei) + CEED_TEMP_U32_1);

    // push edx (edx represents buffer length)
    emit8(0x52);

    // push ecx (ecx == buf_addr (lpBuffer))
    emit8(0x51);

    // push stdout handle from saved location
    emit16(0x35ff);
    emit32(get_data_va(ei) + CEED_STDOUT_HANDLE_RVA);

    // call [fn_addr]
    emit16(0x15ff);
    emit32(fn_WriteConsoleA);
}


pe_emit_read( buf_addr u32, buf_len  u32)
{
    //
    // Uses ReadConsole win32 API.
    //

    // push 0 (pInputControl -> NULL)
    emit16(0x006a);

    // push temp location (lpNumberOfCharsRead)
    emit8(0x68);
    emit32(get_data_va(ei) + CEED_TEMP_U32_1);

    // push buf_len (nNumberOfCharsToRead)
    emit8(0x68);
    emit32(buf_len);

    // push buf_addr (lpBuffer)
    emit8(0x68);
    emit32(buf_addr);

    // push stdin handle from saved location
    emit16(0x35ff);
    emit32(get_data_va(ei) + CEED_STDIN_HANDLE_RVA);

    // call [fn_addr]
    emit16(0x15ff);
    emit32(fn_ReadConsoleA);
}

const CEED_OP_ADD =     0
const CEED_OP_SUB =     1
const CEED_OP_GT =      0
const CEED_OP_EQ =      1

const CEED_TYPE_VAL =   1
const CEED_TYPE_ADDR =  2




 const CEED_TEMP_ATOI_ITOA_BUF_ADDR =    0x900

 const CEED_TEMP_ATOI_ITOA_BUF_LEN =     0x10


chk_code_size( size u32)
{
    if ((size + code_pos) > CEED_MAX_CODE_SIZE) {
        printf("Error: Exceeded maximum CODE size of %d bytes.\n",
               CEED_MAX_CODE_SIZE);
        exit(-1);
    }
}


emit8( i u8)
{
    chk_code_size(1);
    pc_memcpy(&code[code_pos], &i, 1);
    code_pos++;
}


emit16( i u16)
{
    chk_code_size(2);
    pc_memcpy(&code[code_pos], &i, 2);
    code_pos += 2;
}


emit32( i u32)
{
    chk_code_size(4);
    pc_memcpy(&code[code_pos], &i, 4);
    code_pos += 4;
}


emit32at( pos u32,  i u32)
{
    pc_memcpy(&code[pos], &i, 4);
}


pe_emit_indirect_call( fn_addr u32)
{
    // call [fn_addr]
    emit8(0xff);
    emit8(0x15);
    emit32(fn_addr);
}



pe_emit_get_std_handle( handle_type u8,  save_location u32)
{
    // push handle_type
    emit8(0x6a);
    emit8(handle_type);

    pe_emit_indirect_call(fn_GetStdHandle);

    // mov [data_section_va + save_location], eax
    emit8(0xa3);
    emit32(get_data_va(ei) + save_location);
}
*/