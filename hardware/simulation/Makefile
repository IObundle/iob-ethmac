ETH_DIR:=../..

include ../hardware.mk

ifeq ($(VCD), 1)
ICARUS_OPTIONS += -DVCD
endif

ETHOC_SIM_DIR=$(ETHOC_DIR)/scripts
ETHOC_SRC_DIR=$(ETHOC_DIR)/rtl/verilog
ETHOC_SIM_SRC_DIR=$(ETHOC_DIR)/bench/verilog

export

build:
	echo $(ETHOC_DIR)
	mkdir -p ../build/sim && mkdir -p ../log
	cp ../src/* .
	cp $(ETHOC_SRC_DIR)/* .
	cp $(ETHOC_SIM_SRC_DIR)/* .
	cp src/* .
	sleep 1 && sync && rm tb_eth_top.v && iverilog -stb_ethernet *.v $(ICARUS_OPTIONS) -o ../build/sim/ethmac.elf


run: build
	vvp ../build/sim/ethmac.elf

clean:
	rm -rf ../build/sim ../log *.v *.vh BUGS TODO


.PHONY: build run clean
