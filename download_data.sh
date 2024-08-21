#!/bin/bash 

mkdir -p data
cd data

mkdir -p ref
cd ref

# hg38
axel https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta 
axel https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.fai 
axel https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.alt 
axel https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.amb 
axel https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.ann 
axel https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.bwt 
axel https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.pac 
axel https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.64.sa 

# dbsnp_151.vcf.gz
axel https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.dbsnp138.vcf  
axel https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.dbsnp138.vcf.idx  

# Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
axel https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz 
axel https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi 

# 1000G_phase1.snps.high_confidence.hg38.vcf.gz
axel https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/1000G_phase1.snps.high_confidence.hg38.vcf.gz 
axel https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/1000G_phase1.snps.high_confidence.hg38.vcf.gz.tbi 

cd - 

# T7 NA12878 data
# WGS
axel https://demodata.completegenomics.mgiamericas.com/CNR0497793/E100030471QC960_L01_48_1.fq.gz 
axel https://demodata.completegenomics.mgiamericas.com/CNR0497793/E100030471QC960_L01_48_2.fq.gz 

# WES
axel https://demodata.completegenomics.mgiamericas.com/CNR0178967/T7_PE150_NA12878_WES_sample4_1.fq.gz 
axel https://demodata.completegenomics.mgiamericas.com/CNR0178967/T7_PE150_NA12878_WES_sample4_2.fq.gz  

# G400 NA12878 data
# WGS
axel https://demodata.completegenomics.mgiamericas.com/CNR0175139/G400_PE150_NA12878_WGS_V300046476_L01_1.fq.gz 
axel https://demodata.completegenomics.mgiamericas.com/CNR0175139/G400_PE150_NA12878_WGS_V300046476_L01_2.fq.gz 

# WES
axel https://demodata.completegenomics.mgiamericas.com/CNR0117173/G400_PE150_NA12878_WES_MGIEasy_V5_Universal_Library_2.1.fq.gz 
axel https://demodata.completegenomics.mgiamericas.com/CNR0117173/G400_PE150_NA12878_WES_MGIEasy_V5_Universal_Library_2.2.fq.gz 

cd - 

mkdir -p deepvariant_models
cd deepvariant_models 

# T7 weights 
HTTPDIR=https://storage.googleapis.com/deepvariant/complete-case-study-testdata
curl ${HTTPDIR}/complete-t7/weights-51-0.995354.ckpt.data-00000-of-00001 > input/weights-51-0.995354.ckpt.data-00000-of-00001
curl ${HTTPDIR}/complete-t7/weights-51-0.995354.ckpt.index > input/weights-51-0.995354.ckpt.index

# G400 weights 
HTTPDIR=https://storage.googleapis.com/deepvariant/complete-case-study-testdata
curl ${HTTPDIR}/complete-g400/weights-60-0.993753.ckpt.data-00000-of-00001 > input/weights-60-0.993753.ckpt.data-00000-of-00001
curl ${HTTPDIR}/complete-g400/weights-60-0.993753.ckpt.index > input/weights-60-0.993753.ckpt.index

cd - 

mkdir -p outdir