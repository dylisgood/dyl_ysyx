#include <fs.h>

typedef size_t (*ReadFn) (void *buf, size_t offset, size_t len);
typedef size_t (*WriteFn) (const void *buf, size_t offset, size_t len);

extern size_t screen_w, screen_h;

size_t ramdisk_read(void *buf, size_t offset, size_t len);
size_t ramdisk_write(const void *buf, size_t offset, size_t len);
size_t serial_write(const void *buf, size_t offset, size_t len);
size_t events_read(void *buf, size_t offset, size_t len);
size_t dispinfo_read(void *buf, size_t offset, size_t len);
size_t fb_write(const void *buf, size_t offset, size_t len);

typedef struct {
  char *name;
  size_t size;
  size_t disk_offset;
  ReadFn read;
  WriteFn write;
} Finfo;

enum {FD_STDIN, FD_STDOUT, FD_STDERR, FD_FB, FD_EVENT, FD_DISINFO};

size_t invalid_read(void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

size_t invalid_write(const void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

/* This is the information about all files in disk. */
static Finfo file_table[] __attribute__((used)) = {
  [FD_STDIN]  = {"stdin", 0, 0, invalid_read, invalid_write},
  [FD_STDOUT] = {"stdout", 0, 0, invalid_read, serial_write},
  [FD_STDERR] = {"stderr", 0, 0, invalid_read, serial_write},
  [FD_FB]     = {"/dev/fb", 0, 0, invalid_read, fb_write},
  [FD_EVENT]  = {"/dev/events", 0, 0, events_read, invalid_write},
  [FD_DISINFO]= {"/proc/dispinfo", 0, 0, dispinfo_read, invalid_write},
#include "files.h"
};

static size_t open_offset = 0;
char fs_name[64];

int fs_open(const char *pathname, int flags, int mode){
  for(int i = 0; i < sizeof(file_table)/sizeof(Finfo); i++){
    if(strcmp(pathname,file_table[i].name) == 0){
      strcpy(fs_name,pathname);
      open_offset = 0;
      return i;
    }
  }
  return -1;
}

size_t fs_read(int fd, void *buf, size_t len){
  size_t read_len = 0;
  if(open_offset >= file_table[fd].size ){
    return 0;
  }
  if(file_table[fd].read == NULL){
    read_len = ramdisk_read(buf, file_table[fd].disk_offset + open_offset, len);
  }
  else{
    read_len = file_table[fd].read(buf, file_table[fd].disk_offset + open_offset, len);
  }
  if(fd != 1 && fd != 2) open_offset += read_len;
  return read_len;
}

size_t fs_write(int fd, const void *buf, size_t len){
  size_t write_len = 0;
  if(file_table[fd].write == NULL){
    write_len = ramdisk_write(buf, file_table[fd].disk_offset + open_offset, len);
  }
  else {
    write_len = file_table[fd].write(buf, file_table[fd].disk_offset + open_offset, len);
  }
  if(fd != 1 && fd != 2) open_offset += write_len;
  return write_len;
}

size_t fs_lseek(int fd, size_t offset, int whence){
  switch (whence)
  {
  case SEEK_SET:
    open_offset = offset;
    break;
  case SEEK_CUR:
    open_offset += offset;
    break;
  case SEEK_END:
    open_offset = file_table[fd].size + offset;
    break;
  default:
    return -1;
  }

  if(file_table[fd].disk_offset < 0 || file_table[fd].disk_offset > (file_table[fd].disk_offset + file_table[fd].size) ){
    return -1;
  }

  return open_offset;
}

int fs_close(int fd){
  open_offset = 0;
  return 0;
}

void init_fs() {
  // TODO: initialize the size of /dev/fb
  file_table[FD_FB].size = screen_w * screen_h * sizeof(uint32_t);
  file_table[4].size = 64;
  file_table[5].size = 64;
}
