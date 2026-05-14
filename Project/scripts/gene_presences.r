# The goal of this script is to anaylyse the presence of specific genes 
# across different types of s.peidermis and host source 


library(tidyverse)

# Load your final table
data <- read_csv("Project/outputs/strains_with_genes.csv",
                 show_col_types = FALSE)

# Check column names if needed
colnames(data)

# Genes to analyse
genes <- c("mecA", "sdrG", "ica_operon")


type_col <- "type"      # e.g. commensal / pathogenic
source_col <- "Host source"  # e.g. skin / blood / device / nasal


# =========================
# 1. Gene frequency by type
# =========================

freq_by_type <- data %>%
  pivot_longer(
    cols = all_of(genes),
    names_to = "gene",
    values_to = "presence"
  ) %>%
  group_by(.data[[type_col]], gene) %>%
  summarise(
    n_strains = n(),
    n_present = sum(presence == 1, na.rm = TRUE),
    frequency = n_present / n_strains * 100,
    .groups = "drop"
  )

write_csv(freq_by_type, "Project/outputs/gene_frequency_by_type.csv")


fig_type <- ggplot(freq_by_type,
                   aes(x = gene,
                       y = frequency,
                       fill = .data[[type_col]])) +
  geom_col(position = "dodge") +
  labs(
    title = "Gene frequency by strain type",
    x = "Gene",
    y = "Frequency of presence (%)",
    fill = "Type"
  ) +
  theme_minimal()

ggsave(
  "Project/outputs/gene_frequency_by_type.png",
  fig_type,
  width = 8,
  height = 5,
  dpi = 300
)


# ===========================
# 2. Gene frequency by source
# ===========================

freq_by_source <- data %>%
  pivot_longer(
    cols = all_of(genes),
    names_to = "gene",
    values_to = "presence"
  ) %>%
  group_by(.data[[source_col]], gene) %>%
  summarise(
    n_strains = n(),
    n_present = sum(presence == 1, na.rm = TRUE),
    frequency = n_present / n_strains * 100,
    .groups = "drop"
  )

write_csv(freq_by_source, "Project/outputs/gene_frequency_by_source.csv")


fig_source <- ggplot(freq_by_source,
                     aes(x = gene,
                         y = frequency,
                         fill = .data[[source_col]])) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = c(
    "Blood" = "#ac3029",
    "Skin" = "#dca7e0",
    "Device" = "#2345ab",
    "Nasal" = "#51b170",
    "Ocular" = "#11c0e3",
    "Respiratory" = "#0f6048"
  )) +

  labs(
    title = "Gene frequency by isolate source",
    x = "Gene",
    y = "Frequency of presence (%)",
    fill = "Source"
  ) +
  theme_minimal()

ggsave(
  "Project/outputs/gene_frequency_by_source.png",
  fig_source,
  width = 9,
  height = 5,
  dpi = 300
)
