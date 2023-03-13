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
  if(elf_file == NULL) {
    Log("No elf is given. Can't trace function.");
    return;
  }
  else{
    FILE *felf = fopen(elf_file,"r");
    if(!felf){
      printf("open %s failed. \n",elf_file);
      return;
    }
    if(is_elf_64(felf)){
      printf("file type mismatch. \n");
      return;
    }
    
    // 1 读取elf头文件
    Elf64_Ehdr m_elf;
    int jj=fread(&m_elf, 1, sizeof(m_elf), felf);

    // 2 读取所有段结构
    Elf64_Shdr arSection[m_elf.e_shnum];
    fseek(felf, m_elf.e_shoff, SEEK_SET);
    jj=fread(&arSection[0], 1, (m_elf.e_shnum * m_elf.e_shentsize), felf);

    // 3 读取段名字索引
    char arSectionNames[arSection[m_elf.e_shstrndx].sh_size];
    fseek(felf, arSection[m_elf.e_shstrndx].sh_offset, SEEK_SET);
    jj=fread(&arSectionNames, 1, sizeof(arSectionNames), felf);

    // 4 读取段结构和段名字
    SectionMap m_mpSections[m_elf.e_shnum];
    for (Elf64_Half i = 0; i < m_elf.e_shnum; i++) {
        m_mpSections[i].name = &arSectionNames[0] + arSection[i].sh_name;
        m_mpSections[i].shdr = arSection[i];
    }

    //const char findSectionName[] = ".dynstr";
    // 遍历每一个段
    for (Elf64_Half i = 0; i < m_elf.e_shnum; i++) {
        // 输出每个段的名字
        printf("section name :%s\n", m_mpSections[i].name);

/*         // 输出“.dynstr”段的内容
        if (!strcmp(m_mpSections[i].name, findSectionName)) {
            unsigned char content[m_mpSections[i].shdr.sh_size];
            fseek(felf, m_mpSections[i].shdr.sh_offset, SEEK_SET);
            jj=fread(content, 1, m_mpSections[i].shdr.sh_size, felf);
            for (Elf64_Xword j = 0; j < m_mpSections[i].shdr.sh_size; ++j)
                printf("%c", content[j]);
            // printf("%02x", content[i]);对于非字符内容，应该输出十六机制。
        } */
    }
    printf("jj = %d",jj);
    printf("\n");
    fclose(felf);
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
