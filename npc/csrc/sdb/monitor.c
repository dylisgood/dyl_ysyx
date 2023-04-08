#include <getopt.h>
#include <elf.h>
#include "sdb.h"
#include <../../csrc/mem.h>



struct func_struct{
  char name[20];
  uint64_t address;
  uint64_t size;
};

struct func_struct func_trace[10];

static char *img_file = NULL;
static char *elf_file = NULL;
static char *diff_so_file = NULL;
static int difftest_port = 1234;

void init_regex();   //expr.c
void init_wp_pool();  //watchpoint.c
extern "C" void init_disasm(const char *triple);
void init_difftest(char *ref_so_file, long img_size, int port);

int func_num = 0;
void init_ftrace() {
  int sym_num = 0;
  if(elf_file == NULL) {
    printf("No elf is given. Can't trace function.\n");
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

    Elf64_Shdr *sh_table = (Elf64_Shdr *)malloc(sizeof(Elf64_Shdr) * elf_header.e_shnum);
    fseek(fp, elf_header.e_shoff, SEEK_SET);
    sym_num=fread(sh_table, sizeof(Elf64_Shdr), elf_header.e_shnum, fp);

    Elf64_Shdr *strtab = &sh_table[elf_header.e_shstrndx];
    char *sh_strtab = (char *)malloc(strtab->sh_size);
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
    Elf64_Sym *symbols = (Elf64_Sym *)malloc(symtab->sh_size);
    fseek(fp, symtab->sh_offset, SEEK_SET);
    sym_num=fread(symbols, symtab->sh_size, 1, fp);

    if (!strtab_hdr) {
        fprintf(stderr, "No string table found\n");
        return;
    }
    char *strtab1 = (char *)malloc(strtab_hdr->sh_size);
    fseek(fp, strtab_hdr->sh_offset, SEEK_SET);
    sym_num=fread(strtab1, strtab_hdr->sh_size, 1, fp);

    int k = 0;
    sym_num = symtab->sh_size / sizeof(Elf64_Sym);
    for (int i = 0; i < sym_num; i++) {
      Elf64_Sym *sym = &symbols[i];
       if(sym->st_info == 18){
         strcpy(func_trace[k].name,&strtab1[sym->st_name]);
         func_trace[k].address = sym->st_value;
         func_trace[k].size = sym->st_size;
         func_num++;
         k++;
      }
    }
    fclose(fp);
    free(sh_table);
    free(sh_strtab);
    free(symbols);
    free(strtab1);
    return;
  }
}

static long load_img() {
  if(img_file == NULL){
    printf("No image is given, Use the default build-in image.\n");
    return 1024;
  }

  FILE *fp = fopen(img_file,"rb");
  assert( fp!= NULL);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  printf("the image is %s, size = %ld\n", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}

static int parse_args(int argc, char *argv[]){
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    {"elf"      , required_argument, NULL, 'e'},
    {"diff"     , required_argument, NULL, 'd'},
    {"port"     , required_argument, NULL, 'p'},
    { 0      , 0                , NULL,  0 },
  };
  int o;
  while( (o = getopt_long(argc,argv,"-be:d:p:",table,NULL) ) != -1){
    switch (o) {
      case 'b': printf("I enter batch-----------------------\n"); break;
      case 'p': sscanf(optarg, "%d", &difftest_port);break;
      case 'e': elf_file = optarg;break;
      case 'd': diff_so_file = optarg;printf("I get diff_so_diff\n");break;
      case 1: img_file = optarg;return 0;
      default: 
        printf("no img_file");
        exit(0);
    }
  }
  return 0;
}



void init_monitor(int argc, char** argv) {
  parse_args(argc, argv);
    
  init_mem();
  
  int img_size = load_img();
  /* Initialize differential testing. */
  init_difftest(diff_so_file, img_size, difftest_port);

  init_regex();
  init_wp_pool();
  init_ftrace();
  init_disasm("riscv64-pc-linux-gnu");
  
} 