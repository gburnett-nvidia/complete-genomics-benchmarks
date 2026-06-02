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
# Scratch defaults to the fast local NVMe SSD; override with arg 4.
TMP_DIR="${4:-/opt/dlami/nvme/tmp}"
ARGS="$5"
mkdir -p "${TMP_DIR}"

DOCKER_IMAGE="nvcr.io/nvidia/clara/clara-parabricks:4.7.0-1"

# Discover the hardware so we can size the run and label the outputs.
# NUM_GPUS may be set in the environment to benchmark a specific GPU count
# (e.g. NUM_GPUS=2); otherwise we use every GPU on the host.
DETECTED_GPUS=$(nvidia-smi -L | wc -l)
NUM_GPUS="${NUM_GPUS:-$DETECTED_GPUS}"
NUM_CPUS=$(nproc)
THREADS_PER_GPU=$(( NUM_CPUS / NUM_GPUS ))

# Expose exactly NUM_GPUS devices (0..NUM_GPUS-1) to the container.
GPU_DEVICES=$(seq -s, 0 $(( NUM_GPUS - 1 )))
GPU_FLAG="\"device=${GPU_DEVICES}\""

SAMPLE="$(basename -s .fq.gz $FASTQ_1)"
OUT_BAM="${SAMPLE}.fq2bam.${NUM_GPUS}gpu.bam"
LOG_FILE="${SAMPLE}.fq2bam.${NUM_GPUS}gpu.log"

docker run --gpus "${GPU_FLAG}" --rm \
    -v ${DATA_DIR}/data:/data \
    -v ${TMP_DIR}:/tmp \
    ${DOCKER_IMAGE} pbrun fq2bam \
    --ref /data/ref/Homo_sapiens_assembly38.fasta \
    --in-fq /data/${FASTQ_1} /data/${FASTQ_2} \
    --out-bam /data/outdir/${OUT_BAM} \
    --num-gpus ${NUM_GPUS} \
    --bwa-cpu-thread-pool ${THREADS_PER_GPU} \
    --gpusort \
    --gpuwrite \
    --logfile /data/logs/${LOG_FILE} ${ARGS} \
    --tmp-dir /tmp --x3
