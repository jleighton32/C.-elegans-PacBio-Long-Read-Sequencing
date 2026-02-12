library(dplyr)
library(tidyr)
library(readr)
library(writexl)


# Input file

input_file <- "/Users/jleighton32/Library/CloudStorage/OneDrive-Personal/C. elegans FCD-2/Long Read Sequencing/Sniffles/FilteredSVs_Sniffles.tsv"


# Read data

df <- read_tsv(input_file, show_col_types = FALSE)


# Filter SVs
# - Keep all BNDs
# - Keep DEL, INS, DUP, INV only if |SVLEN| >= 50

df_filtered <- df %>%
  mutate(SVLEN_num = suppressWarnings(as.numeric(SVLEN))) %>%
  filter(
    SVTYPE == "BND" |  # Keep all BNDs
      (SVTYPE %in% c("DEL","INS","DUP","INV") & !is.na(SVLEN_num) & abs(SVLEN_num) >= 50)
  )


# Sanity checks

cat("Total SVs before filtering:", nrow(df), "\n")
cat("Total SVs after filtering:", nrow(df_filtered), "\n")

# Min/max for numeric SVs
df_filtered %>%
  filter(SVTYPE %in% c("DEL","INS","DUP","INV")) %>%
  group_by(SVTYPE) %>%
  summarise(
    min_abs_SVLEN = min(abs(SVLEN_num), na.rm = TRUE),
    max_abs_SVLEN = max(abs(SVLEN_num), na.rm = TRUE),
    n = n()
  ) %>%
  print()

# Count BNDs
df_filtered %>%
  filter(SVTYPE == "BND") %>%
  summarise(n_BNDs = n()) %>%
  print()


# Summarise SV counts per sample

sv_summary <- df_filtered %>%
  count(SAMPLE, SVTYPE) %>%
  pivot_wider(
    names_from = SVTYPE,
    values_from = n,
    values_fill = 0
  )


# Output TSV

output_tsv <- "SV_CountsperSample.tsv"
write_tsv(sv_summary, output_tsv)


# Print to console (sanity check)

print(sv_summary)


