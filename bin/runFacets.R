
sample <- as.character(commandArgs(TRUE)[1])
snp_pileup <- as.character(commandArgs(TRUE)[2])

cval_preproc <- as.numeric(commandArgs(TRUE)[3])
window <- as.numeric(commandArgs(TRUE)[4])
cval <- as.numeric(commandArgs(TRUE)[5])

if (!require("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

if (!require("facets", quietly = TRUE)) {
  remotes::install_github("mskcc/facets", build_vignettes = TRUE)
}

if (!require("pctGCdata", quietly = TRUE)) {
  remotes::install_github("mskcc/pctGCdata")
}

library("facets")

# if (seq == "WES"){
#     cval_preproc = 25
#     window = 250
#     cval = 200
# } else if (seq == "WGS"){
#     cval_preproc = 50
#     window = 500
#     cval = 700
# } else {
#     print("error: unknown sequencing method")
# }

x <- readSnpMatrix(snp_pileup)                
xx <- preProcSample(x, gbuild="hg38", cval = cval_preproc, snp.nbhd = window )
y <- procSample(xx, cval = cval)
z <- emcncf(y)

saveRDS(list(preProc=xx,proc=y,emcncf=z), file = paste(sample, "_facets/", sample,"_facets.RDS", sep = ""))

pdf(paste(sample, "_facets/", sample, "_facetsCNV.pdf", sep=""), width=7, height=5)
facets::plotSample(x=y, emfit = z)
mtext(side=3, line=3.2, sample, cex=0.8)
dev.off()

png(paste(sample, "_facets/", sample, "_facetsCNV.png", sep=""), width=7, height=5, res=1000, units='in')
facets::plotSample(x=y, emfit = z)
mtext(side=3, line=3.2, sample, cex=0.8)
dev.off()

pdf(paste(sample, "_facets/", sample, "_facetsQC.pdf", sep=""), width=7, height=5)
logRlogORspider(y$out, y$dipLogR)
dev.off()
