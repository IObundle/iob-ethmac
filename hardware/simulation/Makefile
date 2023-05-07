ETH_DIR:=../..

include ../hardware.mk

ifeq ($(VCD), 1)
ICARUS_OPTIONS += -DVCD
endif

ifeq ($(C), 1)
ICARUS_OPTIONS += -DUSE_IOB_C_INTERFACE
endif

ifeq ($(D), 1)
ICARUS_OPTIONS += -DUSE_IOB_D_INTERFACE
endif


ETHOC_SIM_DIR=$(ETHOC_DIR)/scripts
ETHOC_SRC_DIR=$(ETHOC_DIR)/rtl/verilog
ETHOC_SIM_SRC_DIR=$(ETHOC_DIR)/bench/verilog

all:build

build: ../build/sim/ethmac.elf

../build/sim/ethmac.elf:
	echo $(ETHOC_DIR)
	mkdir -p ../build/sim && mkdir -p ../log
	cp $(ETHOC_SRC_DIR)/* .
	cp $(ETHOC_SIM_SRC_DIR)/* .
ifneq ($(DEBUG),)
	cp ../src/* .
	cp src/* .
endif
	sleep 1 && sync && rm tb_eth_top.v && iverilog -stb_ethernet *.v $(ICARUS_OPTIONS) -o ../build/sim/ethmac.elf

run: ../build/sim/ethmac.elf
	vvp ../build/sim/ethmac.elf

clean:
	rm -rf ../build/sim ../log *.v *.vh BUGS TODO


.PHONY: build run clean
