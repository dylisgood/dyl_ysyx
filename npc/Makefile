TOPNAME = top
NXDC_FILES = constr/top.nxdc
INC_PATH ?=

VERILATOR = verilator
#VERILATOR_CFLAGS += -MMD --build -cc --trace\
				-O3 --x-assign fast --x-initial fast --noassert
VERILATOR_CFLAGS += -MMD --build -cc \
				-O3 --x-assign fast --x-initial fast --noassert #--trace #--prof-cfuncs

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

#DIFF_REF_PATH = $(NEMU_HOME)
DIFF_REF_SO = $(NEMU_HOME)/build/riscv64-nemu-interpreter-so
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
CFLAGS += -O2 $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
#CFLAGS += fPIC
CXXFLAGS += $(shell llvm-config-11 --cxxflags) -fPIE


LDFLAGS += -O2 -lSDL2_image -lreadline
LD2FLAGS += $(shell llvm-config-11 --ldflags)
LD2FLAGS += $(shell llvm-config-11 --libs)

#for difftest: dynamic link riscv
LD3FLAGS += -L/home/dyl/ysyx-workbench/nemu/build
LD3FLAGS += -l:riscv64-nemu-interpreter-so
LD4FLAGS += -L/usr/include/x86_64-linux-gnu/SDL2 -lSDL2

#aurgument  to execute npc
IMG ?= 
override ARGS += -b
override ARGS += $(ARGS_DIFF)

NPC_ECEC = $^ $(ARGS) $(IMG)

$(BIN): $(VSRCS) $(CSRCS) #$(NVBOARD_ARCHIVE) $(addprefix -LDFLAGS , $(LD3FLAGS)) \ 
	@rm -rf $(OBJ_DIR)
	@$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN)) \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LD2FLAGS)) $(addprefix -LDFLAGS , $(LD4FLAGS))
		
all: default

run: $(BIN)
	@$(NPC_ECEC) 

CPUPATH=$(abspath ./vsrc/cpu)
VSRCPATH=$(abspath ./vsrc)

merge:
	cat $(CPUPATH)/cpu.v $(CPUPATH)/decode.v  $(CPUPATH)/gen_imm.v  $(CPUPATH)/gen_src.v  $(CPUPATH)/pc.v  $(CPUPATH)/Registerfile.v  $(CPUPATH)/CSRegister.v \
	$(CPUPATH)/alu.v $(CPUPATH)/multiplier_v1.v  $(CPUPATH)/divider_1.v  $(VSRCPATH)/template/Mux.v  $(VSRCPATH)/template/Reg.v  \
	$(VSRCPATH)/AXI4_Arbiter.v  $(CPUPATH)/cache/I_cache.v $(CPUPATH)/cache/D_cache.v  \
       	> ysyx_22050854.v
		
wave: $(VSRCS) $(CSRCS)
	$(VERILATOR) --cc --exe --build -j 0 --trace sim_main.cpp --top-module $(VSRCS)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: default all clean run

sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@$(NPC_ECEC)
	
include ../Makefile
