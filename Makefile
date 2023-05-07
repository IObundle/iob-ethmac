ETH_DIR:=.

include ./config.mk

#
# SIMULATE RTL
#

sim-build:
	$(MAKE) -C $(ETH_SIM_DIR) build

sim-run:
	$(MAKE) -C $(ETH_SIM_DIR) run

sim-clean:
	make -C $(ETH_SIM_DIR) clean

sim-waves:
	gtkwave hardware/build/sim/*.vcd &

logs:
	cat $(ETHOC_DIR)/log/eth_tb.log 

#
# BUILD TARGETS
#
build-ethernet:
	cd hardware && \
	  ethernet_gen iob_mii.yml


.PHONY: sim-build sim-run sim-clean sim
