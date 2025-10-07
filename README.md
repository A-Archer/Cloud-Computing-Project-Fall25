# Cloud-Computing-Project-Fall25

## Setup

Clone this repo with submodules:
```bash
git clone --recurse-submodules git@github.com:A-Archer/Cloud-Computing-Project-Fall25.git
````

## SimAI vs. OMNeT++ for Cloud Computing Simulation

This section provides an overview of SimAI and OMNeT++, highlighting their distinct focuses to help understand the scope of their application in large-scale computing projects. The explanation is aimed at an undergraduate computer science level.

### What is SimAI?

SimAI (Simulator for AI) is a unified, high-precision simulator specifically designed for Large Language Model (LLM) training infrastructure at scale.

Its core purpose is to validate new hardware designs (GPUs, network topology) and optimize training parameters (parallelism strategies, communication overlap) in a cost-effective, virtual environment. This is essential because training modern LLMs, such as GPT-4, can require tens of thousands of GPUs, making physical experimentation prohibitively expensive.

#### Key Features and Methodology (Full-Stack Fidelity)

**Domain-Specific Focus:** Unlike general-purpose simulators, SimAI is optimized for the full AI training stack.

**High-Fidelity Modeling:** It achieves high accuracy (averaging 98.1% alignment to real-world results) by integrating three critical layers of the system:

1. **Training Workload:** It "hijacks" mainstream AI frameworks (like Megatron and DeepSpeed) to generate accurate, fine-grained LLM training workloads, capturing the exact sequence of operations.
2. **GPU Computation:** It uses an operation database to precisely simulate the execution time of fine-grained GPU kernel operations.
3. **Collective Communication:** It "hijacks" the NVIDIA Collective Communications Library (NCCL) logic to accurately model packet-level behavior for the collective operations (like AllReduce) crucial for distributed GPU communication.

### What is OMNeT++?

OMNeT++ is a general-purpose, extensible, modular, component-based C++ simulation library and framework.

It is primarily used for building network simulators, which can include a broad range of systems like wired and wireless communication networks, on-chip networks, and general queuing systems. While it is not a network simulator itself, it is a powerful platform that provides the core simulation kernel, a topology description language (NED), and an Eclipse-based IDE to build sophisticated, reusable models.

### Key Differences: SimAI vs. OMNeT++

The main difference lies in their scope and domain-specific fidelity. OMNeT++ is a flexible toolkit for general network modeling, whereas SimAI is a specialized, full-stack simulation solution tailored for large-scale AI training environments.

| Feature              | SimAI                                                                                                                                                            | OMNeT++                                                                                                                                                                                                        |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Primary Domain       | Large-Scale Distributed AI/LLM Training (GPUs, Tensor Parallelism, NCCL)                                                                                         | General Networking (Wired, Wireless, On-chip, Queueing)                                                                                                                                                        |
| Simulation Focus     | End-to-end performance of a single LLM training iteration, considering computation and communication overlap at a high level of detail                           | Packet-level network behavior and general queuing/resource modeling                                                                                                                                            |
| Modeling Methodology | Unified, full-stack simulation. It incorporates the logic of specific AI training frameworks (Megatron) and GPU communication libraries (NCCL) for deep fidelity | Classical component-based simulation. Users build network models from C++ modules and define topology using the NED language                                                                                   |
| Limitation for LLM   | None (It is purpose-built for this task)                                                                                                                         | While capable of detailed network simulation, it does not natively understand or model the specialized collective communication logic and kernel optimizations used within distributed LLM training frameworks |

