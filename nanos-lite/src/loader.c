#include <proc.h>
#include <elf.h>
#include <fs.h>

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

uintptr_t loader(PCB *pcb, const char *filename) {
  //printf("-----------------------------enter loader! filename = %s------------------------------------------\n",filename);
  int fd = 0;
  fd = fs_open(filename, 0, 0);
  if(fd==-1){
    Log("Cannot find file %s" ,filename);
    assert(0);
  }
  Elf64_Ehdr  elf_header;
  int num_read = fs_read(fd, &elf_header, sizeof(Elf64_Ehdr)); 
  if(num_read == -1){
    panic("read elf_header fail !");
  }

  assert(*(uint32_t *)elf_header.e_ident == 0x464c457f); //检测是否为ELF文件
  assert(elf_header.e_machine == EXPECT_TYPE);     //检测ELF文件是否为RISCV类型

/*   printf("e_type: %x \n", elf_header.e_type);
  printf("e_magicNum = %x\n",elf_header.e_ident);
  printf("e_entry: %x \n", elf_header.e_entry);
  printf("e_phoff: %x\n", elf_header.e_phoff);
  printf("e_phnum: %x\n", elf_header.e_phnum);
  printf("e_phentsize: %x\n", elf_header.e_phentsize);
  printf("e_machine: %x\n", elf_header.e_machine);
  printf("e_flags: %x\n", elf_header.e_flags);
  printf("e_ident: %s\n", elf_header.e_ident);
  printf("e_ehsize: %x \n\n",elf_header.e_ehsize);
   */

  Elf64_Phdr program_headers[elf_header.e_phnum];
  if( fs_lseek(fd, elf_header.e_phoff, SEEK_SET) == -1){
    panic("locate program header fail! \n");
  }

  num_read = fs_read(fd, program_headers, elf_header.e_phentsize * elf_header.e_phnum);
  if(num_read == -1){
    panic("read program_header fail !");
  }
  
  if( fs_lseek(fd, 0, SEEK_SET) == -1){
    panic("back to original position fail ! \n");
  }

  for(int i = 0; i < elf_header.e_phnum; i++){
    if(program_headers[i].p_type == PT_LOAD){
/*       printf("i = %d \n" ,i);
      printf("ph_table[%d].poffset = %x \n",i, program_headers[i].p_offset);
      printf("ph_table[%d].pflags = %d \n",i, program_headers[i].p_flags & PF_X);
      printf("ph_table[%d].paddr = %x \n",i, program_headers[i].p_paddr);
      printf("ph_table[%d].vaddr = %x \n",i, program_headers[i].p_vaddr);
      printf("ph_table[%d].memsz = %x \n",i, program_headers[i].p_memsz);
      printf("ph_table[%d].filesz = %x \n\n",i, program_headers[i].p_filesz); */
      
      if( fs_lseek(fd, program_headers[i].p_offset, SEEK_SET) == -1){
        panic("go to program_headers[i].p_offset fail ! \n");
      }
      
      fs_read(fd, (void *)program_headers[i].p_vaddr, program_headers[i].p_filesz); //2023.7.5 memsz->file_sz
      if(program_headers[i].p_memsz > program_headers[i].p_filesz){
        memset((void *)( program_headers[i].p_vaddr + program_headers[i].p_filesz ), 0, program_headers[i].p_memsz - program_headers[i].p_filesz);
      }
    }
  }
  //TODO();
  fs_close(fd);
  return elf_header.e_entry;
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  //asm volatile("fence.i");

  Log("Jump to entry = %lx", entry);
  ((void(*)())entry) ();
}

