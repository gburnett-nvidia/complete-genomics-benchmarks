#!/bin/bash 

############################
######## Sample Data #######
############################

DATA_DIR="$PWD/data"
mkdir -p $DATA_DIR

# DNBSEQ-T1+ 
cd $DATA_DIR && \
    aws --profile complete s3 cp s3://cg-nvidia/30x_HG001_DL100002836_L02_NA12878_1.fq.gz && \
    aws --profile complete s3 cp s3://cg-nvidia/30x_HG001_DL100002836_L02_NA12878_2.fq.gz

# DNBSEQ-T7 
cd $DATA_DIR && \
    wget https://demodata.completegenomics.mgiamericas.com/CNR0497793/E100030471QC960_L01_48_1.fq.gz && \
    wget https://demodata.completegenomics.mgiamericas.com/CNR0497793/E100030471QC960_L01_48_2.fq.gz

# DNBSEQ-G400 
cd $DATA_DIR && \
    wget https://demodata.completegenomics.mgiamericas.com/CNR0175139/G400_PE150_NA12878_WGS_V300046476_L01_1.fq.gz && \
    wget https://demodata.completegenomics.mgiamericas.com/CNR0175139/G400_PE150_NA12878_WGS_V300046476_L01_2.fq.gz

############################
###### Reference Data ######
############################

REF_DIR="$DATA_DIR/ref"
mkdir -p $REF_DIR

cd $REF_DIR && \
    wget -c ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg19/ucsc.hg19.dict.gz && gunzip ucsc.hg19.dict.gz && \
    wget -c ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg19/ucsc.hg19.fasta.gz && gunzip ucsc.hg19.fasta.gz && \
    wget -c ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg19/ucsc.hg19.fasta.fai.gz && gunzip ucsc.hg19.fasta.fai.gz && \
    wget https://ftp.ncbi.nih.gov/snp/organisms/human_9606_b151_GRCh37p13/VCF/All_20180423.vcf.gz -O dbsnp_151.vcf.gz && \
    wget https://ftp.ncbi.nih.gov/snp/organisms/human_9606_b151_GRCh37p13/VCF/All_20180423.vcf.gz.tbi -O dbsnp_151.vcf.gz.tbi && \
    wget -c ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg19/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf.gz && \
    wget -c ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/hg19/1000G_phase1.indels.hg19.sites.vcf.gz 

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
