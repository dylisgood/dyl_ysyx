TOPNAME = top
NXDC_FILES = constr/top.nxdc
INC_PATH ?=

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc --trace\
				-O3 --x-assign fast --x-initial fast --noassert\

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

#DIFF_REF_PATH = $(NEMU_HOME)
DIFF_REF_SO = $(NEMU_HOME)/build/riscv64-nemu-interpreter
#MKFLAGS = GUEST_ISA=riscv64 SHARE=1 ENGINE=interpreter

ARGS_DIFF = --diff=$(NEMU_HOME)/build/riscv64-nemu-interpreter-so
#$(DIFF_REF_SO):
#	$(MAKE) -s -C $(DIFF_REF_PATH) make

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
#CSRCS += $(SRC_AUTO_BIND)

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
#CFLAGS += fPIC
CXXFLAGS += $(shell llvm-config-11 --cxxflags) -fPIE

LDFLAGS += -O2 -lSDL2 -lSDL2_image -lreadline
#LDFLAGS += -rdynamic -shared -fPIC
LD2FLAGS += $(shell llvm-config-11 --ldflags)
LD2FLAGS += $(shell llvm-config-11 --libs)
LD3FLAGS += -L$(NEMU_HOME)/build
#LD3FLAGS += -lriscv64-nemu-interpreter-so

ARGS += $(ARGS_DIFF)
IMG ?= 
NPC_ECEC = $^ $(ARGS) $(IMG)

$(BIN): $(VSRCS) $(CSRCS) #$(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	@$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))\
		$(addprefix -LDFLAGS , $(LD3FLAGS))\
 		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LD2FLAGS))
		
		

all: default

run: $(BIN)
	@$(NPC_ECEC) 
		
wave: $(VSRCS) $(CSRCS)
	$(VERILATOR) --cc --exe --build -j 0 --trace sim_main.cpp --top-module $(VSRCS)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: default all clean run

sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@$^
	
include ../Makefile
