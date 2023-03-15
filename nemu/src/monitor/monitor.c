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

static void welcome() {
  Log("Trace: %s", MUXDEF(CONFIG_TRACE, ANSI_FMT("ON", ANSI_FG_GREEN), ANSI_FMT("OFF", ANSI_FG_RED)));
  IFDEF(CONFIG_TRACE, Log("If trace is enabled, a log file will be generated "
        "to record the trace. This may lead to a large log file. "
        "If it is not necessary, you can disable it in menuconfig"));
  Log("Build time: %s, %s", __TIME__, __DATE__);
  printf("Welcome to %s-NEMU!\n", ANSI_FMT(str(__GUEST_ISA__), ANSI_FG_YELLOW ANSI_BG_RED));
  printf("For help, type \"help\"\n");
}

#ifndef CONFIG_TARGET_AM
#include <getopt.h>

void sdb_set_batch_mode();

static char *log_file = NULL;
static char *diff_so_file = NULL;
static char *img_file = NULL;
static int difftest_port = 1234;
static char *elf_file = NULL;

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

typedef struct {
    char*      name;
    Elf64_Shdr shdr;
} SectionMap;

/**
 * 判断是否是ELF64文件。
 */
int is_elf_64(FILE* fp)
{
    char buf[16];
    int  nread = fread(buf, 1, 16, fp);
    fseek(fp, 0, SEEK_SET);
    if (nread < 16) {
        return 1;
    }

    if (strncmp(buf, ELFMAG, SELFMAG)) {
        return 1;
    }

    if (buf[EI_CLASS] != ELFCLASS64) {
        return 1;
    }
    return 0;
}

static void init_ftrace() {
  int jj = 0;
  if(elf_file == NULL) {
    Log("No elf is given. Can't trace function.");
    return;
  }
  else{
    Elf64_Shdr *shdr = NULL;
    Elf64_Ehdr *ehdr = NULL;
    char *strtab = NULL;
    Elf64_Sym *symtab = NULL;
    int i;

    // Open the ELF file
    FILE *fp = fopen(elf_file, "rb");
    if (fp == NULL) {
      printf("Error: Unable to open file\n");
    return;
    }

    // Read the ELF header
    ehdr = malloc(sizeof(Elf64_Ehdr));
    jj=fread(ehdr, sizeof(Elf64_Ehdr), 1, fp);

    // Read the section header table
    shdr = malloc(sizeof(Elf64_Shdr) * ehdr->e_shnum);
    fseek(fp, ehdr->e_shoff, SEEK_SET);
    jj=fread(shdr, sizeof(Elf64_Shdr), ehdr->e_shnum, fp);

    // Find the symbol table and string table sections
    for (i = 0; i < ehdr->e_shnum; i++) {
      if (shdr[i].sh_type == SHT_SYMTAB) {
          printf("haha---------------------------- \n");
          symtab = (Elf64_Sym*)(shdr[i].sh_offset + (unsigned long long)ehdr);
          strtab = (char*)(shdr[shdr[i].sh_link].sh_offset + (unsigned long long)ehdr);
      break;
    }
    }

    // Print out the symbol table
    if (symtab != NULL && strtab != NULL) {
      printf("hahahh ------------\n");
      printf("i = %d \n",i);
      printf("shdr = %ld \n",shdr[i].sh_size / sizeof(Elf64_Sym));
      for(int j = 0; j < (shdr[i].sh_size / sizeof(Elf64_Sym)); j++) {
        printf("%d \n",i);
        printf("hello world\n");
        printf("%s\n", strtab + symtab[i].st_name);
      }
    }

    // Clean up
    printf("jj = %d \n",jj);
    free(ehdr);
    free(shdr);
    fclose(fp);
    return;
  }

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

  init_ftrace();

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
