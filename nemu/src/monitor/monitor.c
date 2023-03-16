/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <memory/paddr.h>
#include <elf.h>

void init_rand();
void init_log(const char *log_file);
void init_mem();
void init_difftest(char *ref_so_file, long img_size, int port);
void init_device();
void init_sdb();
void init_disasm(const char *triple);


#ifndef CONFIG_TARGET_AM
#include <getopt.h>

void sdb_set_batch_mode();
void init_ftrace();

static char *log_file = NULL;
static char *diff_so_file = NULL;
static char *img_file = NULL;
static int difftest_port = 1234;
char *elf_file = NULL;


struct func_trace{
  char *name;
  uint64_t address;
  uint64_t size;
};

struct func_trace *func_struct;

int sym_num = 0;
int func_num = 0;
void init_ftrace() {
  if(elf_file == NULL) {
    Log("No elf is given. Can't trace function.");
    return;
  }
  else{
    Elf64_Ehdr elf_header;
    FILE *fp = fopen(elf_file, "rb");
    if (!fp) {
        perror("Failed to open file");
        return;
    }

    sym_num=fread(&elf_header, sizeof(Elf64_Ehdr), 1, fp);
    if (memcmp(elf_header.e_ident, ELFMAG, SELFMAG) != 0) {
        fprintf(stderr, "Not an ELF file: %s\n", elf_file);
        return;
    }

    Elf64_Shdr *sh_table = malloc(sizeof(Elf64_Shdr) * elf_header.e_shnum);
    fseek(fp, elf_header.e_shoff, SEEK_SET);
    sym_num=fread(sh_table, sizeof(Elf64_Shdr), elf_header.e_shnum, fp);

    Elf64_Shdr *strtab = &sh_table[elf_header.e_shstrndx];
    char *sh_strtab = malloc(strtab->sh_size);
    fseek(fp, strtab->sh_offset, SEEK_SET);
    sym_num=fread(sh_strtab, strtab->sh_size, 1, fp);

    Elf64_Shdr *symtab = NULL;
    Elf64_Shdr *strtab_hdr = NULL;

    for (int i = 0; i < elf_header.e_shnum; i++) {
        if (sh_table[i].sh_type == SHT_SYMTAB) {
            symtab = &sh_table[i];
        } else if (sh_table[i].sh_type == SHT_STRTAB &&
                   strcmp(&sh_strtab[sh_table[i].sh_name], ".strtab") == 0) {
            strtab_hdr = &sh_table[i];
        }
    }

    if (!symtab) {
        fprintf(stderr, "No symbol table found\n");
        return;
    }
    Elf64_Sym *symbols = malloc(symtab->sh_size);
    fseek(fp, symtab->sh_offset, SEEK_SET);
    sym_num=fread(symbols, symtab->sh_size, 1, fp);

    if (!strtab_hdr) {
        fprintf(stderr, "No string table found\n");
        return;
    }
    char *strtab1 = malloc(strtab_hdr->sh_size);
    fseek(fp, strtab_hdr->sh_offset, SEEK_SET);
    sym_num=fread(strtab1, strtab_hdr->sh_size, 1, fp);

    sym_num = symtab->sh_size / sizeof(Elf64_Sym);
    for (int i = 0; i < sym_num; i++) {
      Elf64_Sym *sym = &symbols[i];
       if(sym->st_info == 18){
         func_num++;
      }
    }
    func_struct = (struct func_trace*)malloc(func_num *sizeof(struct func_trace));
    for (int i = 0; i < sym_num; i++) {
      Elf64_Sym *sym = &symbols[i];
       if(sym->st_info == 18){
         //strcpy(func_struct->name,"hello");
         func_struct->address = sym->st_value;
         func_struct->size = sym->st_size;
      }
      func_struct++;
    }
    for(int i=0; i<func_num;i++){
      printf("func_struct[%d].name = %lx\n",i,func_struct[i].address);
    }

/*     printf("%-20s %-20s %-20s %-20s\n", "Name", "Address", "Size", "Type");
    for (int i = 0; i < symtab->sh_size / sizeof(Elf64_Sym); i++) {
        Elf64_Sym *sym = &symbols[i];
        printf("%-20s %-20p %-20lu %-20d\n",
               &strtab1[sym->st_name], (void *) sym->st_value, (unsigned long) sym->st_size, sym->st_info); 
    } */
    fclose(fp);
    free(sh_table);
    free(sh_strtab);
    free(symbols);
    free(strtab1);
    return;
  }
}

static void welcome() {
  Log("Trace: %s", MUXDEF(CONFIG_TRACE, ANSI_FMT("ON", ANSI_FG_GREEN), ANSI_FMT("OFF", ANSI_FG_RED)));
  IFDEF(CONFIG_TRACE, Log("If trace is enabled, a log file will be generated "
        "to record the trace. This may lead to a large log file. "
        "If it is not necessary, you can disable it in menuconfig"));
  Log("Build time: %s, %s", __TIME__, __DATE__);
  printf("Welcome to %s-NEMU!\n", ANSI_FMT(str(__GUEST_ISA__), ANSI_FG_YELLOW ANSI_BG_RED));
  printf("For help, type \"help\"\n");
}

static long load_img() {
  if (img_file == NULL) {
    Log("No image is given. Use the default build-in image.");
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  Assert(fp, "Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  Log("The image is %s, size = %ld", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}

static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    {"log"      , required_argument, NULL, 'l'},
    {"elf"      , required_argument, NULL, 'e'},
    {"diff"     , required_argument, NULL, 'd'},
    {"port"     , required_argument, NULL, 'p'},
    {"help"     , no_argument      , NULL, 'h'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhl:d:p:", table, NULL)) != -1) {
    switch (o) {
      case 'b': sdb_set_batch_mode(); break;
      case 'p': sscanf(optarg, "%d", &difftest_port); break;
      case 'l': log_file = optarg; break;
      case 'e': elf_file = optarg; break;
      case 'd': diff_so_file = optarg; break;
      case 1: img_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-e,--elf=elf_file       input elf from FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

void init_monitor(int argc, char *argv[]) {
  /* Perform some global initialization. */

  /* Parse arguments. */
  parse_args(argc, argv);

  /* Set random seed. */
  init_rand();

  /* Open the log file. */
  init_log(log_file);

  /* Initialize memory. */
  init_mem();

  /* Initialize devices. */
  IFDEF(CONFIG_DEVICE, init_device());

  /* Perform ISA dependent initialization. */
  init_isa();

  /* Load the image to memory. This will overwrite the built-in image. */
  long img_size = load_img();

  /* Initialize differential testing. */
  init_difftest(diff_so_file, img_size, difftest_port);

  /* Initialize the simple debugger. */
  init_sdb();

  IFDEF(CONFIG_FTRACE,init_ftrace());

  IFDEF(CONFIG_ITRACE, init_disasm(
    MUXDEF(CONFIG_ISA_x86,     "i686",
    MUXDEF(CONFIG_ISA_mips32,  "mipsel",
    MUXDEF(CONFIG_ISA_riscv32, "riscv32",
    MUXDEF(CONFIG_ISA_riscv64, "riscv64", "bad")))) "-pc-linux-gnu"
  ));

  /* Display welcome message. */
  welcome();
}
#else // CONFIG_TARGET_AM
static long load_img() {
  extern char bin_start, bin_end;
  size_t size = &bin_end - &bin_start;
  Log("img size = %ld", size);
  memcpy(guest_to_host(RESET_VECTOR), &bin_start, size);
  return size;
}

void am_init_monitor() {
  init_rand();
  init_mem();
  init_isa();
  load_img();
  IFDEF(CONFIG_DEVICE, init_device());
  welcome();
}
#endif
