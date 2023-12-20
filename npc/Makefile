TOPNAME = top
NXDC_FILES = constr/top.nxdc
INC_PATH ?=

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc \
				-O3 --x-assign fast --x-initial fast --noassert #--trace #--prof-cfuncs

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

ARGS_DIFF = --diff=$(NEMU_HOME)/build/riscv64-nemu-interpreter-so

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CFLAGS += -O2 $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
CXXFLAGS += $(shell llvm-config-11 --cxxflags) -fPIE

LDFLAGS += -O2 -lSDL2_image -lreadline
LD2FLAGS += $(shell llvm-config-11 --ldflags)
LD2FLAGS += $(shell llvm-config-11 --libs)
#SDL
LD2FLAGS += -L/usr/include/x86_64-linux-gnu/SDL2 -lSDL2

#aurgument  to execute npc
IMG ?= 
override ARGS += -b
override ARGS += $(ARGS_DIFF)

NPC_ECEC = $^ $(ARGS) $(IMG)

$(BIN): $(VSRCS) $(CSRCS) #$(NVBOARD_ARCHIVE)\  # $(addprefix -LDFLAGS , $(LD4FLAGS))
	@rm -rf $(OBJ_DIR)
	@$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN)) \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LD2FLAGS))
		
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
