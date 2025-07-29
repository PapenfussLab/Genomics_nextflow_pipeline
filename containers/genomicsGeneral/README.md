This container includes all the basic tools:

- samtools
- htslib (bgzip, tabix)
- bwa-mem2
- bcftools
- gatk4
- vcftools
- bedtools
- picard tools
- sambamba ?



 Generate Reference Models
 ./synggen mode=0 bamlist=string bed=string fasta=string commonsnps=string [rlen=int] [seqprot=int] [mrq=int] [mbq=int] [minvaf=double] [out=string] [threads=int]

 Generate Synthetic Reads
 ./synggen mode=1 bed=string fasta=string rdm=string qm=string [pbe=string] [snps=string] [cnv=string] [pm=string] [indel=string] [seqprot=int] [insmode=int] [insize=int] [insizestd=float] [adm=double] [nreads=int] [out=string] [threads=int] [seed=int]

bamlist=string
 List of BAM files paths
bed=string
 List of genomic captured regions in BED format
fasta=string
 Reference genome FASTA
commonsnps=string
 Common SNPs catalogue (VCF format)
seqprot=int
 Sequencing protocol (single-end = 0, paired-end = 1)
 (default 0)
mrq=int
 Min read quality for PBE calculation
 (default 10)
mbq=int
 Min base quality for PBE calculation
 (default 10)
minvaf=double
 Minimum VAF to include a genomic position in the PBE model
 (default 0.01)
out=string
 Output folder name
threads=int
 number of threads used (if available) for the computation
 (default 1)
rdm=string
 Read depth model (RDM) file path
pbe=string
 Pair Base Error model (PBE) file path
qm=string
 Quality model (QM) file path
snps=string
 Germline SNPs (synggen format) file path
cna=string
 Somatic copy number aberrations (synngen format) file path
pm=string
 Somatic point mutations (synngen format) file path
indel=string
 Somatic indels (synngen format) file path
insmode=int
 Insert size model creation
 (0 = MEAN and STD, 1 = DISTRIBUTION, default 0)
insize=int
 Use a specific insert size for data generation
 (default 100)
insizestd=double
 Use a specific insert size STD for data generation
 (default 5 percent of the insert size)
tc=double
 Tumor content value for tumor sample generation
 (default 0.0)
nreads=int
 Number of reads to generate
 (default 1000)
rlen=int
 Length of the read
 (default 100)
seed=int
 Reads generation seed, should be >0
 (default random)