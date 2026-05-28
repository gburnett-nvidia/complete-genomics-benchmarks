#!/bin/bash
set -euo pipefail
trap 'kill -TERM 0' INT TERM

############################
######## Sample Data #######
############################

DATA_DIR="$PWD/data"
mkdir -p $DATA_DIR

# DNBSEQ-T7+
wget -c -P "$DATA_DIR" https://demodata.completegenomics.mgiamericas.com/Demo_Data/T7plus/T7plus_WGS_PE150_HG002_PCR_Free_Read_1.fq.gz &
wget -c -P "$DATA_DIR" https://demodata.completegenomics.mgiamericas.com/Demo_Data/T7plus/T7plus_WGS_PE150_HG002_PCR_Free_Read_2.fq.gz &
wait

############################
###### Reference Data ######
############################

REF_DIR="$DATA_DIR/ref"
mkdir -p $REF_DIR

# GATK hg38 resource bundle. .fai and .dict are NOT gzipped in the hg38 bundle.
# known_indels.vcf.gz lives in the gcp-public-data--broad-references bucket, not the Broad FTP.

# Critical path: fasta download -> decompress -> bwa index (~1-2hr, single-threaded).
# Backgrounded so the other downloads and VCF re-indexing overlap with it.
(
    cd "$REF_DIR" && \
        wget -c ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg38/Homo_sapiens_assembly38.fasta.gz && \
        pigz -df Homo_sapiens_assembly38.fasta.gz && \
        bwa index Homo_sapiens_assembly38.fasta
) &

# All other downloads in parallel; track PIDs so we can wait on these without
# blocking on the fasta+bwa pipeline above.
DL_PIDS=()
wget -c -P "$REF_DIR" ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg38/Homo_sapiens_assembly38.dict & DL_PIDS+=($!)
wget -c -P "$REF_DIR" ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg38/Homo_sapiens_assembly38.fasta.fai & DL_PIDS+=($!)
wget -c https://ftp.ncbi.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/All_20180418.vcf.gz -O "$REF_DIR/dbsnp_151.vcf.gz" & DL_PIDS+=($!)
wget -c https://ftp.ncbi.nih.gov/snp/organisms/human_9606_b151_GRCh38p7/VCF/All_20180418.vcf.gz.tbi -O "$REF_DIR/dbsnp_151.vcf.gz.tbi" & DL_PIDS+=($!)
wget -c -P "$REF_DIR" ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg38/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz & DL_PIDS+=($!)
wget -c -P "$REF_DIR" ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg38/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi & DL_PIDS+=($!)
wget -c -P "$REF_DIR" https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.known_indels.vcf.gz & DL_PIDS+=($!)
wget -c -P "$REF_DIR" https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.known_indels.vcf.gz.tbi & DL_PIDS+=($!)
for pid in "${DL_PIDS[@]}"; do wait "$pid"; done

# hg38 known-sites VCFs already ship bgzipped with .tbi — only re-index if missing.
# Run both re-indexings in parallel, alongside the still-running bwa index.
index_files=("Mills_and_1000G_gold_standard.indels.hg38" "Homo_sapiens_assembly38.known_indels")
for index in "${index_files[@]}"; do
    if [ ! -f "$REF_DIR/$index.vcf.gz.tbi" ]; then
        ( cd "$REF_DIR" && pigz -d $index.vcf.gz && bgzip -@ $(nproc) $index.vcf && tabix -p vcf $index.vcf.gz ) &
    fi
done

# Wait for bwa index (and any re-indexing) to finish.
wait

##########################################
######### Optional (Concordance) #########
##########################################

# No liftover needed — GIAB publishes GRCh38 truth sets directly.
# Sample FASTQs above are HG002, so the matching truth is the AshkenazimTrio HG002 v4.2.1 set.

# TRUTH_DIR="$DATA_DIR/truth"
# mkdir -p $TRUTH_DIR
# cd $TRUTH_DIR && \
#     wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/AshkenazimTrio/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz && \
#     wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/AshkenazimTrio/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz.tbi && \
#     wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/AshkenazimTrio/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed
# wget https://github.com/broadinstitute/picard/releases/download/2.27.5/picard.jar
