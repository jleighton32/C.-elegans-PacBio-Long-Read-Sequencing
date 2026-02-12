setwd("/Users/jleighton32/Library/CloudStorage/OneDrive-Personal/C. elegans FCD-2/Long Read Sequencing/Sniffles")

list.files()

files <- list.files(pattern = "\\.tsv$")

#Read tsv table
sv_list <- lapply(files, function(f) {
  read.table(f, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
})

sv_all <- do.call(rbind, sv_list)

head(sv_all)
dim(sv_all)

#Create merged table
write.table(
  sv_all,
  file = "Sniffles_merged.tsv",
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)

#Confirm all rows were merged
files <- list.files(
  pattern = "\\.sniffles\\.tsv$"
)
rows_per_file <- sapply(files, function(f) {
  nrow(read.table(f, header = TRUE, sep = "\t"))
})
sum(rows_per_file)
nrow(sv_all)
