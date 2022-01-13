# Prepare.Transcriptome.for.Velocity
# Source: https://combine-lab.github.io/alevin-tutorial/2020/alevin-velocity/

suppressPackageStartupMessages({
  library("getopt")
  library("optparse")
  library("R.utils")
  library("dplyr")
  library("BSgenome")
  library("eisaR")
  library("GenomicFeatures")
  library("Biostrings")
})

arguments <- commandArgs(trailingOnly = TRUE)

option_list <- list(
  make_option("--gtf", dest = "gtf"),
  make_option("--genome", dest = "genome.fa"),
  make_option("--length", dest = "length"),
  make_option("--trim", dest = "trim"),
  make_option("--type", dest = "type"),
  make_option("--join", dest = "join")
)

opt <- parse_args(OptionParser(option_list = option_list),
  positional_arguments = TRUE,
  args = arguments
)$options

gtf = opt$gtf
genome.fa = opt$genome.fa
type = opt$type ## "separate", or "collapse"
read_length = as.integer(opt$length) ## Insert Length, used to set flank length around introns
flank_trim_length = as.integer(opt$trim) # New tutorial uses 5, not clear why.
flank_length = as.integer(read_length - flank_trim_length)
join_introns = as.logical(opt$join)

# genome.fa.out <- gsub(basename(genome.fa), pattern=".gz$", replacement="")
# genome.fa.out <- gsub(genome.fa.out, pattern=".fa$", replacement="")
# genome.fa.out <- paste0(genome.fa.out,".expanded")

sequences.out <- gsub(basename(gtf), pattern = ".gz$", replacement = "")
sequences.out <- gsub(sequences.out, pattern = ".gtf$", replacement = "")
sequences.out <- paste0(sequences.out, ".velocity")

grl <- eisaR::getFeatureRanges(
  gtf = gtf,
  featureType = c("spliced", "intron"),
  intronType = type,
  flankLength = flank_length,
  joinOverlappingIntrons = join_introns, # New tutorial sets = TRUE, not clear why
  verbose = FALSE
)

genome <- Biostrings::readDNAStringSet(
  genome.fa
) # The "Error in (function (x)  : attempt to apply non-function" message is expected.

gtf_df <- rtracklayer::import(gtf)
gtf_df <- as.data.frame(gtf_df)
gene_meta <- distinct(gtf_df[, c("gene_id", "gene_name")])

names(genome) <- sapply(strsplit(names(genome), " "), .subset, 1)
seqs <- GenomicFeatures::extractTranscriptSeqs(
  x = genome,
  transcripts = grl
)

Biostrings::writeXStringSet(
  seqs,
  filepath = paste0(sequences.out, ".", as.character(flank_length), "bp_flank.fa.gz"), compress = TRUE
)

eisaR::exportToGtf(
  grl,
  filepath = paste0(sequences.out, ".gtf")
)
gzip(paste0(sequences.out, ".gtf"), destname = paste0(sequences.out, ".", as.character(flank_length), "bp_flank.gtf.gz"), overwrite = TRUE, remove = TRUE)

splicing_meta <- metadata(grl)$corrgene
metadata_table <- merge(x = splicing_meta, y = gene_meta, by.x = "spliced", by.y = "gene_id", all.x = TRUE)
metadata_table <- metadata_table[match(splicing_meta$spliced, metadata_table$spliced), ]

write.table(metadata_table,
  file = paste0(sequences.out, ".", as.character(flank_length), "bp_flank.features.tsv"),
  row.names = FALSE, col.names = TRUE, quote = FALSE, sep = "\t"
)

df <- eisaR::getTx2Gene(
  grl,
  filepath = paste0(sequences.out, ".", as.character(flank_length), "bp_flank.tgMap.tsv")
)

mt_df <- unique(gtf_df[(gtf_df$seqnames == "chrM" | gtf_df$seqnames == "MT"), c("gene_id"), drop = FALSE])
mt_df_2 <- as.data.frame(paste(mt_df$gene_id, "I", sep = "-"))
colnames(mt_df_2) <- colnames(mt_df)
mt_df <- rbind(mt_df, mt_df_2)
write.table(mt_df, paste0(sequences.out, ".", as.character(flank_length), "bp_flank.mtGenes.txt"), quote = FALSE, row.names = FALSE, col.names = FALSE, sep = "\t")

rrna_df <- unique(gtf_df[gtf_df$gene_type == "rRNA", c("gene_id"), drop = FALSE])
rrna_df_2 <- as.data.frame(paste(rrna_df$gene_id, "I", sep = "-"))
colnames(rrna_df_2) <- colnames(rrna_df)
rrna_df <- rbind(rrna_df, rrna_df_2)
write.table(rrna_df, paste0(sequences.out, ".", as.character(length), "bp_flank.rrnaGenes.txt"), quote = FALSE, row.names = FALSE, col.names = FALSE, sep = "\t")


invisible(file.remove(gtf))
