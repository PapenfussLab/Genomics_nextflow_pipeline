## Tool list

This container includes all the basic tools:

- samtools
- htslib (bgzip, tabix)
- bwa-mem2
- bcftools
- gatk4  (call by 'gatk')
- (java via sdkman)
- picard tools (call by 'picard', which runs 'java -jar /opt/picard/picard.jar')
- freebayes 
- vcftools
- bedtools
- sambamba

- also has python (3.12), although this is not explicitly defined I think...

Only 'bedtools' was installed via apt. 

Other tools were all downloaded to /opt/

## build

Build command:

`apptainer build --fakeroot container.sif genomicsGeneral.def`

Tested on both WEHI Milton HPC and Nectar Virual Desktop (Rocky Linux 9)




