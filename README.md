This document is mainly intended to help users get started quickly. 

Please use GCC 9.5.0 version to rebuild!!!!!

**Configuration Files and Reproduction Instructions (Step-by-Step)**

**1 Configuration Files**

The experiments rely on the following key configuration files within the SimAI framework:

  * **`inputs/config/SimAI.conf`**:

      * **Role**: Defines system-wide simulation parameters such as network latency, bandwidth, and congestion control settings (DCQCN parameters).
      * **Key Settings**: `link_bandwidth = 100Gbps`, `link_latency = 500ns`.

  * **`example/microAllReduce.txt`**:

      * **Role**: Defines the collective communication workload. It specifies the communication pattern (AllReduce), message size, and participating nodes.
      * **Usage**: The reproduction script dynamically modifies this file to sweep message sizes from 2MB to 512MB for the baseline performance test.

  * **`inputs/topo/gen_Topo_Template.py`**:

      * **Role**: A Python script used to generate the network topology file.
      * **Usage**: Used to generate the 128-GPU Spectrum-X (Fat-Tree) topology for control plane verification.

**2 Reproduction Instructions (Step-by-Step)**

We provide a set of scripts to streamline the entire process. Follow these steps to reproduce the results from scratch.

**Step 1: Environment Setup**

Clone the repository and install dependencies.

```bash
cd ~
git clone -b Zeli_Ma_test https://github.com/A-Archer/Cloud-Computing-Project-Fall25.git SimAI_MARC_Run
cd SimAI_MARC_Run
git submodule update --init --recursive
pip install matplotlib pandas
```

**Step 2: Compilation**

Build the modified NS-3 kernel and Astra-Sim integration using the provided build script.

```bash
./scripts/build.sh -c ns3
```

**Step 3: Verification**

Verify the functionality of both the Data Plane and Control Plane.

```bash
./scripts/run_verify.sh
```

  * **Data Plane**: Runs `verify_forwarding` to confirm packet replication.
  * **Control Plane**: Runs SimAI on a 128-GPU topology to confirm the `MarcController` correctly builds the multicast tree (logs `Tree constructed successfully`).

**Step 4: Benchmarking**

Run the performance experiments to generate data.

```bash
./scripts/run_benchmark.sh
```

  * **Real Measurement**: Runs `marc_perf_test.cc` to generate `marc_results.csv` (Figure A data).
  * **Baseline Sweep**: Runs SimAI in a loop to generate `ring_results.csv` (Figure B baseline data).

**Step 5: Visualization**

Generate the final result charts.

```bash
./scripts/run_plot.sh
```

  * **Output**: Generates `Figure_A_Real_Measurement.png` and `Figure_B_Full_System_Projection.png` in the project root.

**Explanation of Commands**

  * **`cd ~`**: Ensures you start from the home directory.
  * **`git clone ...`**: Downloads the specific branch of your project code.
  * **`git submodule update ...`**: Downloads the source code for `ns-3-alibabacloud` and `astra-sim-alibabacloud` submodules.
  * **`pip install ...`**: Installs Python libraries needed for plotting. 
  * **`./scripts/build.sh -c ns3`**: Compiles the entire project, including your modifications to the NS-3 kernel (`ipv4-l3-protocol.cc`, `marc-header.h/cc`) and the Astra-Sim application layer (`entry.h`). 
  * **`./scripts/run_verify.sh`**: Validates correctness. It runs a simple data plane test and a complex control plane test on the Spectrum-X topology. 
  * **`./scripts/run_benchmark.sh`**: Generates performance data. It runs the `marc_perf_test.cc` script to get real MARC performance and loops SimAI simulations to get Ring baseline performance.
  * **`./scripts/run_plot.sh`**: Creates the visual charts. It uses Python scripts to read the CSV data generated in the previous step and plot the comparison graphs. 
