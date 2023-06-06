#include <proc.h>
#include <elf.h>
/* #include <unistd.h>
#include <fcntl.h>
#include <stdio.h> */
/* #include <sys/types.h>
#include <sys/stat.h> */
//#include <sys/mman.h>

#if defined(__ISA_AM_NATIVE__)
# define EXPECT_TYPE EM_X86_64
#elif defined(__ISA_X86__)
# define EXPECT_TYPE EM_X86_64
#elif defined(__ISA_MIPS32__)
#define EXPECT_TYPE EM_MIPS
#elif defined(__ISA_RISCV32__) || defined(__ISA_RISCV64__)
#define EXPECT_TYPE EM_RISCV
#else
# error Unsupported ISA
#endif

#ifdef __LP64__
# define Elf_Ehdr Elf64_Ehdr
# define Elf_Phdr Elf64_Phdr
#else
# define Elf_Ehdr Elf32_Ehdr
# define Elf_Phdr Elf32_Phdr
#endif
extern uint8_t ramdisk_start[];
//extern uint8_t ramdisk_end;
//#define BUF_SIZE ((&ramdisk_end) - (&ramdisk_start))

void ramdisk_read(void *buf, size_t offset, size_t len);

static uintptr_t loader(PCB *pcb, const char *filename) {
  Elf_Ehdr* elf_header = (Elf64_Ehdr*)(ramdisk_start);

  uint16_t e_type = elf_header->e_type;
  unsigned char *e_magicNum = elf_header->e_ident;
  uint32_t e_entry = elf_header->e_entry;
  uint32_t e_phoff = elf_header->e_phoff;
  uint32_t e_phnum = elf_header->e_phnum;

  assert(*(uint32_t *)elf_header->e_ident == 0x464c457f); //检测是否为ELF文件
  assert(elf_header->e_machine == EXPECT_TYPE);     //检测ELF文件是否为RISCV类型

  printf("e_type: %x \n", e_type);
  printf("e_magicNum = %x\n",e_magicNum);
  printf("e_entry: %x \n", e_entry);
  printf("e_phoff: %x\n", e_phoff);
  printf("e_phnum: %x\n", e_phnum);
  printf("e_machine: %x\n", elf_header->e_machine);
  printf("e_flags: %x\n", elf_header->e_flags);
  printf("e_ident: %s\n", elf_header->e_ident);
  printf("e_ehsize: %x \n\n",elf_header->e_ehsize);

  Elf_Phdr* program_header_table = (Elf_Phdr*)( (char*)elf_header + e_phoff);

  for (int i = 0; i < elf_header->e_phnum; i++) {
    Elf_Phdr* program_header = &program_header_table[i];
    if(program_header->p_type == PT_LOAD){
      printf("ph_table[%d].poffset = %x \n",i, program_header->p_offset);
      printf("ph_table[%d].pflags = %d \n",i, program_header->p_flags & PF_X);
      printf("ph_table[%d].paddr = %x \n",i, program_header->p_paddr);
      printf("ph_table[%d].vaddr = %x \n",i, program_header->p_vaddr);
      printf("ph_table[%d].memsz = %x \n",i, program_header->p_memsz);
      printf("ph_table[%d].filesz = %x \n\n",i, program_header->p_filesz);

      memcpy((void *)program_header->p_vaddr, (ramdisk_start + program_header->p_offset), program_header->p_memsz);
      if(program_header->p_memsz > program_header->p_filesz){
        memset((void *)( program_header->p_vaddr + program_header->p_filesz ), 0, program_header->p_memsz - program_header->p_filesz);
      }
    }
}
  //TODO();
  return elf_header->e_entry;
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %lx", entry);
  ((void(*)())entry) ();
}

