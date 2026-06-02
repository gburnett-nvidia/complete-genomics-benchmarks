#!/bin/bash

# Parabricks DeepSomatic (tumor-only) benchmark. GPU count is detected
# automatically and the run is sized from the host hardware.
#
# Usage: ./deepsomatic.sh <data_dir> <in_bam> <tmp_dir> [extra_args]
#   data_dir  - parent dir containing data/ subdir (mounted into the container)
#   in_bam    - input tumor BAM (relative to data/outdir/)
#   tmp_dir   - scratch dir for intermediate files (mounted into the container)
#   extra_args- optional pass-through args (e.g. "--use-wes-model", "--in-normal-bam ...")

DATA_DIR="$1"
IN_BAM="$2"
# Scratch defaults to the fast local NVMe SSD; override with arg 3.
TMP_DIR="${3:-/opt/dlami/nvme/tmp}"
ARGS="$4"
mkdir -p "${TMP_DIR}"

DOCKER_IMAGE="nvcr.io/nvidia/clara/clara-parabricks:4.7.0-1"

# Discover the hardware so we can size the run and label the outputs.
# NUM_GPUS may be set in the environment to benchmark a specific GPU count
# (e.g. NUM_GPUS=2); otherwise we use every GPU on the host.
DETECTED_GPUS=$(nvidia-smi -L | wc -l)
NUM_GPUS="${NUM_GPUS:-$DETECTED_GPUS}"

# Expose exactly NUM_GPUS devices (0..NUM_GPUS-1) to the container.
GPU_DEVICES=$(seq -s, 0 $(( NUM_GPUS - 1 )))
GPU_FLAG="\"device=${GPU_DEVICES}\""

# 4 streams/GPU keeps device-memory use modest on the L4 (24 GB). CPU threads
# per stream are sized so all host vCPUs are used (matching fq2bam/haplotypecaller):
# total worker threads = NUM_GPUS * STREAMS_PER_GPU * THREADS_PER_STREAM ~= NUM_CPUS.
NUM_CPUS=$(nproc)
STREAMS_PER_GPU=4
THREADS_PER_STREAM=$(( NUM_CPUS / (NUM_GPUS * STREAMS_PER_GPU) ))
(( THREADS_PER_STREAM < 1 )) && THREADS_PER_STREAM=1

SAMPLE="$(basename -s .bam $IN_BAM)"
OUT_VCF="${SAMPLE}.deepsomatic.${NUM_GPUS}gpu.vcf"
LOG_FILE="${SAMPLE}.deepsomatic.${NUM_GPUS}gpu.log"

docker run --gpus "${GPU_FLAG}" --rm \
    -v ${DATA_DIR}/data:/data \
    -v ${TMP_DIR}:/tmp \
    ${DOCKER_IMAGE} pbrun deepsomatic \
    --ref /data/ref/Homo_sapiens_assembly38.fasta \
    --in-tumor-bam /data/outdir/${IN_BAM} \
    --out-variants /data/outdir/${OUT_VCF} \
    --num-gpus ${NUM_GPUS} \
    --num-streams-per-gpu ${STREAMS_PER_GPU} \
    --num-cpu-threads-per-stream ${THREADS_PER_STREAM} \
    --run-partition \
    --logfile /data/logs/${LOG_FILE} ${ARGS} \
    --tmp-dir /tmp --x3
