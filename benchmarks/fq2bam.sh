#!/bin/bash

# Parabricks fq2bam benchmark. GPU count and CPU thread pool are sized
# automatically from the host hardware.
#
# Usage: ./fq2bam.sh <data_dir> <fastq_1> <fastq_2> <tmp_dir> [extra_args]
#   data_dir  - parent dir containing data/ subdir (mounted into the container)
#   fastq_1   - R1 FASTQ (relative to data/)
#   fastq_2   - R2 FASTQ (relative to data/)
#   tmp_dir   - scratch dir for intermediate files (mounted into the container)
#   extra_args- optional pass-through args (e.g. "--knownSites ...", BQSR, etc.)

DATA_DIR="$1"
FASTQ_1="$2"
FASTQ_2="$3"
TMP_DIR="$4"
ARGS="$5"

DOCKER_IMAGE="nvcr.io/nvidia/clara/clara-parabricks:4.7.0-1"

# Discover the hardware so we can size the run and label the outputs.
NUM_GPUS=$(nvidia-smi -L | wc -l)
NUM_CPUS=$(nproc)
THREADS_PER_GPU=$(( NUM_CPUS / NUM_GPUS ))

SAMPLE="$(basename -s .fq.gz $FASTQ_1)"
OUT_BAM="${SAMPLE}.fq2bam.${NUM_GPUS}gpu.bam"
LOG_FILE="${SAMPLE}.fq2bam.${NUM_GPUS}gpu.log"

docker run --gpus all --rm \
    -v ${DATA_DIR}/data:/data \
    -v ${TMP_DIR}:/tmp \
    ${DOCKER_IMAGE} pbrun fq2bam \
    --ref /data/ref/ucsc.hg19.fasta \
    --in-fq /data/${FASTQ_1} /data/${FASTQ_2} \
    --out-bam /data/outdir/${OUT_BAM} \
    --num-gpus ${NUM_GPUS} \
    --bwa-cpu-thread-pool ${THREADS_PER_GPU} \
    --run-partition \
    --no-alt-contigs \
    --gpusort \
    --gpuwrite \
    --logfile /data/logs/${LOG_FILE} ${ARGS} \
    --tmp-dir /tmp --x3
