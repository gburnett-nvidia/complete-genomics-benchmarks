#!/bin/bash

# Parabricks HaplotypeCaller benchmark. GPU count and CPU thread pool are
# sized automatically from the host hardware.
#
# Usage: ./haplotypecaller.sh <data_dir> <in_bam> <tmp_dir> [extra_args]
#   data_dir  - parent dir containing data/ subdir (mounted into the container)
#   in_bam    - input BAM (relative to data/outdir/)
#   tmp_dir   - scratch dir for intermediate files (mounted into the container)
#   extra_args- optional pass-through args (e.g. "--gvcf", "--in-recal-file ...")

DATA_DIR="$1"
IN_BAM="$2"
TMP_DIR="$3"
ARGS="$4"

DOCKER_IMAGE="nvcr.io/nvidia/clara/clara-parabricks:4.7.0-1"

# Discover the hardware so we can size the run and label the outputs.
NUM_GPUS=$(nvidia-smi -L | wc -l)
NUM_CPUS=$(nproc)
THREADS_PER_GPU=$(( NUM_CPUS / NUM_GPUS ))

SAMPLE="$(basename -s .bam $IN_BAM)"
OUT_VCF="${SAMPLE}.haplotypecaller.${NUM_GPUS}gpu.vcf"
LOG_FILE="${SAMPLE}.haplotypecaller.${NUM_GPUS}gpu.log"

# --htvc-low-memory keeps the GPU memory footprint modest.
docker run --gpus all --rm \
    -v ${DATA_DIR}/data:/data \
    -v ${TMP_DIR}:/tmp \
    ${DOCKER_IMAGE} pbrun haplotypecaller \
    --ref /data/ref/ucsc.hg19.fasta \
    --in-bam /data/outdir/${IN_BAM} \
    --out-variants /data/outdir/${OUT_VCF} \
    --num-gpus ${NUM_GPUS} \
    --num-htvc-threads ${THREADS_PER_GPU} \
    --run-partition \
    --htvc-low-memory \
    --logfile /data/logs/${LOG_FILE} ${ARGS} \
    --tmp-dir /tmp --x3
