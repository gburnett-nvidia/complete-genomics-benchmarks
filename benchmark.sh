#!/bin/bash
#
# Parabricks GPU-scaling benchmark sweep.
#
# Runs all four benchmarks (fq2bam, haplotypecaller, deepvariant, deepsomatic)
# at each GPU count in GPU_COUNTS. For every GPU count we first align the FASTQ
# pair with fq2bam, then feed the resulting BAM into the three variant callers.
# Output BAMs/VCFs and logs are labelled with the GPU count (e.g. ".2gpu.").
#
# Usage: ./benchmark.sh [data_dir] [tmp_dir]
#   data_dir - parent dir containing the data/ subdir (default: repo root)
#   tmp_dir  - scratch dir for intermediate files (default: <data_dir>/tmp)
#
# GPU counts can be overridden:  GPU_COUNTS="2 4" ./benchmark.sh
set -euo pipefail

# The data was copied to the fast local NVMe SSD; keep inputs, scratch, and
# outputs all on that drive for best I/O. Override NVME_DIR if it moves.
NVME_DIR="${NVME_DIR:-/opt/dlami/nvme}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${1:-$NVME_DIR}"
TMP_DIR="${2:-$NVME_DIR/tmp}"
BENCHMARK_PATH="${REPO_DIR}/benchmarks"

# GPU counts to sweep. This host has 4 L4 GPUs; 8 requires an 8-GPU instance.
GPU_COUNTS="${GPU_COUNTS:-2 4}"

# Sample: HG002 WGS from the DNBSEQ-T7+ (paired FASTQ in data/).
FASTQ_1="HG002_ML150002521_UDB-386_1.fq.gz"
FASTQ_2="HG002_ML150002521_UDB-386_2.fq.gz"

OUTDIR="${DATA_DIR}/data/outdir"
mkdir -p "${TMP_DIR}" "${DATA_DIR}/data/logs" "${OUTDIR}"

# Resume helper: run a benchmark only if its output isn't already present.
# This lets an interrupted sweep be relaunched without redoing finished steps.
# NOTE: skip is based purely on "output file exists and is non-empty", so if a
# step was killed mid-write, delete its partial output before relaunching.
run_step() {
    local out="$1"; shift   # expected output file (relative to OUTDIR)
    if [[ -s "${OUTDIR}/${out}" ]]; then
        echo ">> SKIP (already done): ${out}"
        return 0
    fi
    "$@"
}

for n in ${GPU_COUNTS}; do
    echo "========================================================"
    echo "  GPU count: ${n}"
    echo "========================================================"
    export NUM_GPUS="${n}"

    SAMPLE="$(basename -s .fq.gz ${FASTQ_1})"
    BAM="${SAMPLE}.fq2bam.${n}gpu.bam"
    BAM_SAMPLE="$(basename -s .bam ${BAM})"

    # 1) Alignment: FASTQ -> BAM
    run_step "${BAM}" \
        "${BENCHMARK_PATH}/fq2bam.sh" "${DATA_DIR}" "${FASTQ_1}" "${FASTQ_2}" "${TMP_DIR}"

    # 2) Variant callers on that BAM
    run_step "${BAM_SAMPLE}.haplotypecaller.${n}gpu.vcf" \
        "${BENCHMARK_PATH}/haplotypecaller.sh" "${DATA_DIR}" "${BAM}" "${TMP_DIR}"
    run_step "${BAM_SAMPLE}.deepvariant.${n}gpu.vcf" \
        "${BENCHMARK_PATH}/deepvariant.sh" "${DATA_DIR}" "${BAM}" "${TMP_DIR}"

    # DeepSomatic is disabled: Parabricks 4.7 requires a matched --in-normal-bam
    # (no tumor-only data available for this sample). Re-enable when a normal BAM
    # exists by restoring the run_step below.
    # run_step "${BAM_SAMPLE}.deepsomatic.${n}gpu.vcf" \
    #     "${BENCHMARK_PATH}/deepsomatic.sh" "${DATA_DIR}" "${BAM}" "${TMP_DIR}"
done

echo "All benchmarks complete. Logs in ${DATA_DIR}/data/logs, outputs in ${DATA_DIR}/data/outdir"
