This document is mainly intended to help users get started quickly. 
please use GCC 9.5.0 version to rebuild!!!!!
Run the following commands:


```bash
cd ~

git clone -b Zeli_Ma_test https://github.com/A-Archer/Cloud-Computing-Project-Fall25.git SimAI_MARC_Run

cd SimAI_MARC_Run

git submodule update --init --recursive

pip install matplotlib pandas

./scripts/build.sh -c ns3

./scripts/run_verify.sh
./scripts/run_benchmark.sh
./scripts/run_plot.sh
