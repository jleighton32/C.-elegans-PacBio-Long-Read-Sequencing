
# Load libraries
library(tidyverse)
library(ggpubr)
library(ggdist)

# Input file
input_file <- "/Users/jleighton32/Library/CloudStorage/OneDrive-Personal/C. elegans FCD-2/Long Read Sequencing/Sniffles/FilteredSVs_Sniffles.tsv"

# -------------------------------
# Load and filter data
# -------------------------------
df <- read_tsv(input_file, col_names = TRUE)

df <- df %>%
  filter(SVTYPE == "DEL") %>%
  mutate(
    value = abs(as.numeric(SVLEN))
  ) %>%
  filter(!is.na(value), value >= 50)


# -------------------------------
# Assign groups
# -------------------------------
df <- df %>%
  mutate(
    Group = case_when(
      SAMPLE %in% c("1-bc2065", "2-bc2066", "3-bc2067", "4-bc2068", "5-bc2609") ~ "N2_NT",
      SAMPLE %in% c("11-bc2075", "12-bc2076", "13-bc2077", "14-bc2078", "15-bc2079") ~ "N2_HU",
      SAMPLE %in% c("6-bc2070", "7-bc2071", "8-bc2072", "9-bc2073", "10-bc2074") ~ "tm1298_NT",
      SAMPLE %in% c("16-bc2080", "17-bc2081", "18-bc2082", "19-bc2083", "20-bc2084") ~ "tm1298_HU",
      TRUE ~ NA_character_
    )
  ) %>%
  drop_na(Group)

  
df$Group <- factor(df$Group, levels = c("N2_NT", "N2_HU", "tm1298_NT", "tm1298_HU"))

# -------------------------------
# Define comparisons
# -------------------------------
my_comparisons <- list(
  c("N2_NT", "N2_HU"),
  c("N2_NT", "tm1298_NT"),
  c("N2_NT", "tm1298_HU"),
  c("N2_HU", "tm1298_NT"),
  c("N2_HU", "tm1298_HU"),
  c("tm1298_NT", "tm1298_HU")
)

# -------------------------------
# Wilcoxon tests
# -------------------------------
stat.test <- compare_means(
  value ~ Group,
  data = df,
  method = "wilcox.test",
  comparisons = my_comparisons
)

# Significant results only (for plotting)
stat.sig <- stat.test %>% filter(p < 0.05)

# y positions for brackets
stat.sig <- stat.sig %>%
  arrange(p) %>%
  mutate(
    y.position = seq(
      from = max(df$value) * 1.05,
      by = max(df$value) * 0.05,
      length.out = n()
    )
  )

# -------------------------------
# Plot
# -------------------------------
p <- ggplot(df, aes(x = Group, y = value, fill = Group)) +
  stat_halfeye(
    adjust = 0.5,
    justification = -0.25,
    .width = 0,
    point_colour = NA,
    width = 0.75
  ) +
  geom_boxplot(
    width = 0.1,
    outlier.shape = NA,
    alpha = 0.6
  ) +
  geom_jitter(
    aes(color = Group),
    width = 0.12,
    alpha = 0.4,
    size = 1.5
  ) +
  stat_pvalue_manual(
    stat.sig,
    label = "p.signif",
    tip.length = 0.01
  ) +
  scale_fill_brewer(palette = "Set2") +
  scale_color_brewer(palette = "Dark2") +
  scale_x_discrete(expand = expansion(mult = c(0.1, 0.1))) +
  labs(
    x = "Group",
    y = "Deletion Length (bp)",
    title = "Deletion Length (Deletions 50 bp)"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "none",
    plot.title = element_text(hjust = 0.5),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black")
  )

print(p)

# -------------------------------
# Export Wilcoxon summary table
# -------------------------------
group_means <- df %>%
  group_by(Group) %>%
  summarise(mean_value = mean(value), .groups = "drop")

export_table <- stat.test %>%
  left_join(group_means, by = c("group1" = "Group")) %>%
  rename(mean1 = mean_value) %>%
  left_join(group_means, by = c("group2" = "Group")) %>%
  rename(mean2 = mean_value) %>%
  mutate(
    mean_diff = mean2 - mean1,
    direction = case_when(
      mean_diff > 0 ~ paste(group2, ">", group1),
      mean_diff < 0 ~ paste(group2, "<", group1),
      TRUE ~ "No difference"
    )
  ) %>%
  select(group1, group2, mean1, mean2, mean_diff, p, p.signif, direction) %>%
  arrange(p)

write_csv(export_table, "Deletions_50bp.csv")

# -------------------------------
# Save plot
# -------------------------------
ggsave(
  filename = "Deletions_50bp.tiff",
  plot = p,
  path = "/Users/jleighton32/Library/CloudStorage/OneDrive-Personal/C. elegans FCD-2/Long Read Sequencing/Sniffles",
  width = 10,
  height = 7,
  units = "in",
  dpi = 300
)

cat("Analysis complete: plot and Wilcoxon summary table exported.\n")
