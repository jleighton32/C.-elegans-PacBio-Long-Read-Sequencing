library(dplyr)
library(tidyr)
library(readr)
library(writexl)


# Input file
input_file <- "/Users/jleighton32/Library/CloudStorage/OneDrive-Personal/C. elegans FCD-2/Long Read Sequencing/Sniffles/FilteredSVs_Sniffles.tsv"


# Read data
df <- read_tsv(input_file, show_col_types = FALSE)


# Assign groups
df <- df %>%
  mutate(
    Group = case_when(
      SAMPLE %in% c("1-bc2065", "2-bc2066", "3-bc2067", "4-bc2068", "5-bc2069") ~ "N2_NT",
      SAMPLE %in% c("11-bc2075", "12-bc2076", "13-bc2077", "14-bc2078", "15-bc2079") ~ "N2_HU",
      SAMPLE %in% c("6-bc2070", "7-bc2071", "8-bc2072", "9-bc2073", "10-bc2074") ~ "tm1298_NT",
      SAMPLE %in% c("16-bc2080", "17-bc2081", "18-bc2082", "19-bc2083", "20-bc2084") ~ "tm1298_HU",
      TRUE ~ NA_character_
    )
  )


# Summarise SV counts per group
sv_summary <- df %>%
  filter(!is.na(Group)) %>%
  count(Group, SVTYPE) %>%
  pivot_wider(
    names_from = SVTYPE,
    values_from = n,
    values_fill = 0
  )


# Output files
output_tsv   <- "SV_totalcounts_per_group.tsv"
output_excel <- "SV_totalcounts_per_group.xlsx"

write_tsv(sv_summary, output_tsv)
write_xlsx(sv_summary, output_excel)

# -------------------------------
# Print to console (sanity check)
# -------------------------------
print(sv_summary)

