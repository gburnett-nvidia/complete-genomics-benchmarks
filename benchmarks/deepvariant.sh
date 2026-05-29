#!/bin/bash

# Parabricks DeepVariant benchmark. GPU count is detected automatically and
# the run is sized from the host hardware.
#
# Usage: ./deepvariant.sh <data_dir> <in_bam> <tmp_dir> [extra_args]
#   data_dir  - parent dir containing data/ subdir (mounted into the container)
#   in_bam    - input BAM (relative to data/outdir/)
#   tmp_dir   - scratch dir for intermediate files (mounted into the container)
#   extra_args- optional pass-through args (e.g. "--use-wes-model", "--gvcf")

DATA_DIR="$1"
IN_BAM="$2"
TMP_DIR="$3"
ARGS="$4"

DOCKER_IMAGE="nvcr.io/nvidia/clara/clara-parabricks:4.7.0-1"

# Discover the hardware so we can size the run and label the outputs.
NUM_GPUS=$(nvidia-smi -L | wc -l)

SAMPLE="$(basename -s .bam $IN_BAM)"
OUT_VCF="${SAMPLE}.deepvariant.${NUM_GPUS}gpu.vcf"
LOG_FILE="${SAMPLE}.deepvariant.${NUM_GPUS}gpu.log"

# 4 streams/GPU keeps device-memory use modest; 6 CPU threads per stream
# balances CPU and GPU work.
docker run --gpus all --rm \
    -v ${DATA_DIR}/data:/data \
    -v ${TMP_DIR}:/tmp \
    ${DOCKER_IMAGE} pbrun deepvariant \
    --ref /data/ref/ucsc.hg19.fasta \
    --in-bam /data/outdir/${IN_BAM} \
    --out-variants /data/outdir/${OUT_VCF} \
    --num-gpus ${NUM_GPUS} \
    --num-streams-per-gpu 4 \
    --num-cpu-threads-per-stream 6 \
    --run-partition \
    --use-tf32 \
    --logfile /data/logs/${LOG_FILE} ${ARGS} \
    --tmp-dir /tmp --x3
