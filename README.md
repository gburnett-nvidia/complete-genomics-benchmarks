# Benchmarking Alignment and Variant Calling on Whole Genome Data from Complete Genomics using Parabricks on AWS 

This is a quick start guide for benchmarking Parabricks germline workflows using data from Complete Genomics sequencers. Parabricks is a GPU accelerated toolkit for secondary analysis in genomics. In this guide, we will show that Parabricks runs in a fast, and therefore cost effective, manner on the cloud using data from the DNBSEQ-T7 and DNBSEQ-G400 sequencers from Complete Genomics. 

Genomic files such as FASTQ and BAM files can easily reach into the hundreds of GB each. When running studies that involve hundreds of thousands of these files, it easily becomes terabytes of data and processing all of that data becomes very costly. This is especially apparent when running on the cloud where users are charged by the hour, so every minute of compute counts. The faster we can churn through this data, the lower the cost will be. 

## Quick Start 

To get started as quickly as possible, run these two scripts: 

```
./install.sh 
./run.sh 
```

## Pre-Requisites 
### Software
These benchmarks were performed using Parabricks version 4.4.0-1 which is publicly available as a Docker container on the NVIDIA GPU Cloud (NGC) by running the following command: 

`docker pull nvcr.io/nvidia/clara/clara-parabricks:4.4.0-1`

Other software prerequisites include: 

| Software | Version | Purpose |
| :----------------: | :------: | :----: |
| [bwa](https://github.com/lh3/bwa) | 0.7.18 | Indexing the reference |
| [seqtk](https://github.com/lh3/seqtk) | 1.4 | Downsampling FASTQ |
| [pigz](https://linux.die.net/man/1/pigz) | 2.6 | Fast gzip compression |

These packages can be installed by running

`./install.sh` 

### Hardware
For Parabricks, there are two categories of GPUs that we recommend: High Performance GPUs (A100, H100, L40S) and Low Cost GPUs (A10, L4). These benchmarks were validated using L40S instances and L4 instances on AWS, however any similarly configured machine will work. Be sure to check the Parabricks documentation for minimum requirements. Below are the exact configurations used in our validation: 

| Configuration | L4 | L40S |
| :----------------: | :------: | :----: |
| Instance Type | g6.24xlarge | g6e.24xlarge |
| OS | Ubuntu | Ubuntu |
| AMI | Deep Learning Nvidia Driver | Deep Learning Nvidia Driver |
| Num GPUs | 4 | 4 |
| vCPUs | 96 | 96 |
| CPU Memory | 384 GB | 768 GB |
| On Demand Cost per Hour | $6.68 | $15.07 |

## Dataset
This benchmark uses WGS data from HG002 sampled at 100x coverage on the DNBSEQ-T7+ Complete Genomics sequencer. To download the data, run the following script: 

`./download.sh`

Note: This is ~300GB of data and may take some time to download. 

### Pre-Processing
The data as it exists publicly is almost ready to use for our benchmarking. For an apples-to-apples comparison, we want both of the WGS samples to have the same coverage. The T7 WGS data has a coverage of 46x and the G400 WGS data has a coverage of 30x. To resolve this, we will downsample the T7 WGS data by 65%. To achieve this, we can run: 

`./downsample.sh <T7_file> 0.65` 

This will rename E100030471QC960_L01_48_1.fq.gz to E100030471QC960_L01_48_1.30x.fq.gz and then the data will be ready to run through the benchmarks. 

The resulting coverages, numbers of reads, and file sizes are summarized for each sample in the table below: 

|  | DNBSEQ-T7 | DNBSEQ-G400 |
| :----------------: | :------: | :----: |
| Coverage | 30x | 30x |
| Reads | 658 Million | 955 Million |
| File Size | 72 GB | 69 GB |

## Running the Benchmarks 
Looking in the benchmarks folder will show us what benchmarking scripts are available: 

```
benchmarks/
├── L4
│   ├── deepvariant.sh
│   └── germline.sh
└── L40S
    ├── deepvariant.sh
    └── germline.sh
```

For each set of hardware, there is a germline and a deepvariant script. The separation is due to different optimization flags used for each configuration. To learn more about these optimizations, check out the Parabricks documentation. The germline script runs Parabricks germline pipeline, which aligns the FASTQ files and runs HaplotypeCaller. The deepvariant script runs the Parabricks deepvariant variant caller. 

The benchmark.sh script accepts one argument for the hardware type, which matches the folder name within the benchmarks folder. For example, to run the L4 benchmarks, we can run: 

`./benchmark.sh L4`

and similarly to run the L40S benchmarks, we can run: 

`./benchmark.sh L40S`

### Performance optimization 

To maximize Parabricks performance, it’s best that all the file reading and writing happen on the fast SSD on the machine. 
