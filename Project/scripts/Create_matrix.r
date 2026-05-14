# The goal of this code is to create a presence or absence matrix from the the ABRicate hits than added to the original csv containing metadata and clean the strains containing no hits

library(tidyverse)

# 1. Load files
hits <- read_tsv("Project/outputs/abricate/strain_gene_matches_from_raws.tsv", show_col_types = FALSE)
metadata <- read_csv2("Project/Strains_cleaned.csv", show_col_types = FALSE)

# 2. Clean ABRicate table
hits_clean <- hits %>%
  mutate(
    gene_clean = case_when(
      gene == "U43366.1" ~ "ica_operon",
      gene == "mecA" ~ "mecA",
      gene == "sdrG" ~ "sdrG",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(gene_clean))

# 3. Create presence/absence matrix
gene_matrix <- hits_clean %>%
  distinct(strain, gene_clean) %>%
  mutate(present = 1) %>%
  pivot_wider(
    names_from = gene_clean,
    values_from = present,
    values_fill = 0
  )

# 4. Add a total number of detected genes per strain
gene_matrix <- gene_matrix %>%
  mutate(total_genes_detected = mecA + sdrG + ica_operon)

# 5. Merge with original metadata
# Normalize strain names: replace spaces with underscores to match merged file format
# Keep only first occurrence of each strain (remove duplicates from metadata)
metadata <- metadata %>%
  distinct(Strain, .keep_all = TRUE) %>%
  mutate(Strain = str_replace_all(Strain, " ", "_"))
final_table <- metadata %>%
  left_join(gene_matrix, by = c("Strain" = "strain")) %>%
  mutate(
    across(c(mecA, sdrG, ica_operon, total_genes_detected),
           ~ replace_na(.x, 0))
  )

# 6. Remove strains with no hits
final_table_with_hits <- final_table %>%
  filter(total_genes_detected > 0)

# 7. Save output
write_csv(final_table_with_hits, "Project/outputs/strains_with_genes.csv")
write_csv(gene_matrix, "Project/outputs/gene_presence_absence_matrix.csv")
