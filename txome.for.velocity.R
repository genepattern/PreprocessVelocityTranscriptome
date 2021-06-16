#Prepare.Transcriptome.for.Velocity
# Source: https://combine-lab.github.io/alevin-tutorial/2020/alevin-velocity/

suppressPackageStartupMessages({
library("devtools")
})
suppressMessages(suppressWarnings(install.packages("R.utils", repos = "https://cloud.r-project.org/")))
suppressMessages(suppressWarnings(install.packages("getopt", repos = "https://cloud.r-project.org/")))
suppressMessages(suppressWarnings(install.packages("optparse", repos = "https://cloud.r-project.org/")))
if (!requireNamespace("BiocManager", quietly = TRUE))
    suppressMessages(suppressWarnings(install.packages("BiocManager", repos = "https://cloud.r-project.org/")))
suppressMessages(suppressWarnings(BiocManager::install("rtracklayer", quiet = TRUE)))
suppressMessages(suppressWarnings(BiocManager::install("GenomicFeatures", quiet = TRUE)))
suppressMessages(suppressWarnings(BiocManager::install("Biostrings", quiet = TRUE)))
suppressMessages(suppressWarnings(BiocManager::install("BSgenome", quiet = TRUE)))
suppressMessages(suppressWarnings(BiocManager::install("eisaR", quiet = TRUE)))

suppressPackageStartupMessages({
    library("getopt")
    library("optparse")
    library("R.utils")
    library("BSgenome")
    library("eisaR")
    library("GenomicFeatures")
#    library(SummarizedExperiment)
#    library(tximeta)
#    library(rjson)
#    library(reticulate)
#    library(SingleCellExperiment)
#    library(scater)
    library("Biostrings")
})

arguments <- commandArgs(trailingOnly=TRUE)

option_list <- list(
make_option("--gtf", dest = "gtf"),
make_option("--genome", dest = "genome.fa"),
make_option("--type", dest = "type"),
make_option("--length", dest = "length"))

opt <- parse_args(OptionParser(option_list = option_list), positional_arguments = TRUE,
 args = arguments)$options

gtf = opt$gtf
genome.fa = opt$genome.fa
type = opt$type ## "separate", or "collapse"
length = opt$length ## Insert Length - 1 (default 90)

#genome.fa.out <- gsub(basename(genome.fa), pattern=".gz$", replacement="")
#genome.fa.out <- gsub(genome.fa.out, pattern=".fa$", replacement="")
#genome.fa.out <- paste0(genome.fa.out,".expanded")

sequences.out <- gsub(basename(gtf), pattern=".gz$", replacement="")
sequences.out <- gsub(sequences.out, pattern=".gtf$", replacement="")
sequences.out <- paste0(sequences.out,".velocity")

grl <- eisaR::getFeatureRanges(
  gtf = gtf,
  featureType = c("spliced", "intron"),
  intronType = type,
  flankLength = as.integer(length),
  joinOverlappingIntrons = FALSE,
  verbose = FALSE
)

genome <- Biostrings::readDNAStringSet(
    genome.fa
) #The "Error in (function (x)  : attempt to apply non-function" message is expected.

names(genome) <- sapply(strsplit(names(genome), " "), .subset, 1)
seqs <- GenomicFeatures::extractTranscriptSeqs(
  x = genome,
  transcripts = grl
)

Biostrings::writeXStringSet(
    seqs, filepath = paste0(sequences.out,".",as.character(length),"bp_flank.fa.gz"), compress=TRUE
)

eisaR::exportToGtf(
  grl,
  filepath = paste0(sequences.out,".gtf")
)
gzip(paste0(sequences.out,".gtf"), destname=paste0(sequences.out,".",as.character(length),"bp_flank.gtf.gz"), overwrite=TRUE, remove=TRUE)

write.table(
    metadata(grl)$corrgene,
    file = paste0(sequences.out,".",as.character(length),"bp_flank.features.tsv"),
    row.names = FALSE, col.names = TRUE, quote = FALSE, sep = "\t"
)

df <- eisaR::getTx2Gene(
    grl, filepath = paste0(sequences.out,".",as.character(length),"bp_flank.tgMap.tsv")
)

gtf_df <- rtracklayer::import(gtf)
gtf_df=as.data.frame(gtf_df)
mt_df=unique(gtf_df[(gtf_df$seqnames=="chrM"|gtf_df$seqnames=="MT"),c("gene_id"),drop=FALSE])
mt_df_2=as.data.frame(paste(mt_df$gene_id,"I", sep="-"))
colnames(mt_df_2)=colnames(mt_df)
mt_df=rbind(mt_df,mt_df_2)
write.table(mt_df,paste0(sequences.out,".",as.character(length),"bp_flank.mtGenes.txt"),quote=FALSE,row.names=FALSE,col.names=FALSE,sep="\t")

rrna_df=unique(gtf_df[gtf_df$gene_type=="rRNA",c("gene_id"),drop=FALSE])
rrna_df_2=as.data.frame(paste(rrna_df$gene_id,"I", sep="-"))
colnames(rrna_df_2)=colnames(rrna_df)
rrna_df=rbind(rrna_df,rrna_df_2)
write.table(rrna_df,paste0(sequences.out,".",as.character(length),"bp_flank.rrnaGenes.txt"),quote=FALSE,row.names=FALSE,col.names=FALSE,sep="\t")


invisible(file.remove(gtf))
