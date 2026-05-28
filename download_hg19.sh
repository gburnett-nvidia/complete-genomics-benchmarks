#!/bin/bash 

############################
######## Sample Data #######
############################

DATA_DIR="$PWD/data"
mkdir -p $DATA_DIR

# DNBSEQ-T7+ 
cd $DATA_DIR && \
    wget https://demodata.completegenomics.mgiamericas.com/Demo_Data/T7plus/T7plus_WGS_PE150_HG002_PCR_Free_Read_1.fq.gz && \
    wget https://demodata.completegenomics.mgiamericas.com/Demo_Data/T7plus/T7plus_WGS_PE150_HG002_PCR_Free_Read_2.fq.gz

############################
###### Reference Data ######
############################

REF_DIR="$DATA_DIR/ref"
mkdir -p $REF_DIR

cd $REF_DIR && \
    wget -nc --progress=bar:force 2>&1 https://s3.amazonaws.com/parabricks.sample/parabricks_sample.tar.gz

# Index reference files 
cd $REF_DIR && bwa index ucsc.hg19.fasta

# Note: Mills and 1000G need to be bgzipped and re-indexed 
index_files=("Mills_and_1000G_gold_standard.indels.hg19.sites" "1000G_phase1.indels.hg19.sites")
for index in ${index_files[@]}; do
    cd $REF_DIR && \
        pigz -d $index.vcf.gz && \
        bgzip $index.vcf && \
        tabix -p vcf $index.vcf.gz 
done

##########################################
### Optional (Concordance and Liftover)###
##########################################

# TRUTH_DIR="$DATA_DIR/truth"
# mkdir -p $TRUTH_DIR
# cd $TRUTH_DIR && \
#     wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/NA12878_HG001/NISTv4.2.1/GRCh37/HG001_GRCh37_1_22_v4.2.1_benchmark.vcf.gz && \
#     wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/NA12878_HG001/NISTv4.2.1/GRCh37/HG001_GRCh37_1_22_v4.2.1_benchmark.vcf.gz.tbi && \
#     wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/NA12878_HG001/NISTv4.2.1/GRCh37/HG001_GRCh37_1_22_v4.2.1_benchmark.bed
# wget https://github.com/broadinstitute/picard/releases/download/2.27.5/picard.jar
# wget https://github.com/broadgsa/gatk/blob/master/public/chainFiles/b37tohg19.chain
# wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/liftOver && chmod +x liftOver 
