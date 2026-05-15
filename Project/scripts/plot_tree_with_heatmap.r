# Tree + metadata + gene presence heatmap

library(tidyverse)
library(ape)
library(ggtree)
library(ggnewscale)

# 1. File paths
tree_file <- "Project/raw_outputs/parsnp_tree/parsnp_output_no_maf/parsnp.tree"
metadata_file <- "Project/outputs/strains_with_genes.csv"

output_pdf <- "Project/outputs/parsnp_tree/tree_with_metadata_heatmap.pdf"
output_png <- "Project/outputs/parsnp_tree/tree_with_metadata_heatmap.png"

# 2. Read tree
tree <- read.tree(tree_file)

# 3. Remove Parsnp reference duplicate if present (ref sequence might be duplicated ) 
tree <- drop.tip(tree, grep("\\.ref$", tree$tip.label, value = TRUE))

# 4. Clean tree tip labels
tree$tip.label <- basename(tree$tip.label)
tree$tip.label <- str_replace(tree$tip.label, "\\.fna$", "")
tree$tip.label <- str_replace(tree$tip.label, "_GCA_.*$", "")


# 5. Read metadata and clean it
metadata <- read_csv(metadata_file, show_col_types = FALSE)

metadata <- metadata %>%
  mutate(
    Strain = str_replace_all(Strain, " ", "_"),
    type = tolower(type)
  ) %>%
  select(Strain, type, mecA, ica_operon)

# Remove duplicate strains
metadata <- metadata %>%
  distinct(Strain, .keep_all = TRUE)

# 6. Keep all strains from the tree
all_tree_strains <- tibble(Strain = tree$tip.label)

# 7. Add metadata where available
metadata <- all_tree_strains %>%
  left_join(metadata, by = "Strain") %>%
  mutate(
    type = replace_na(type, "unknown"),
    across(c(mecA, ica_operon), ~ replace_na(.x, NA_real_))
  )

# 8. Prepare heatmap data
heatmap_data <- metadata %>%
  column_to_rownames("Strain") %>%
  select(mecA, ica_operon)

# 9. Prepare type annotation
type_data <- metadata %>%
  select(Strain, type)

# 10. Build tree
p <- ggtree(tree, layout = "rectangular") %<+% type_data +
  geom_tiplab(aes(color = type), size = 2.2, align = TRUE, linesize = 0.2) +
  scale_color_manual(
    values = c(
      "pathogen" = "red",
      "commensal" = "darkgreen",
      "unknown" = "grey40"
    ),
    na.value = "grey40",
    name = "Strain type"
  ) +
  theme_tree2() +
  ggtitle("Core-genome phylogenetic tree with gene presence/absence")

# 11. Add heatmap
p2 <- gheatmap(
  p,
  heatmap_data,
  offset = 0.03,
  width = 0.18,
  colnames = TRUE,
  colnames_angle = 45,
  colnames_offset_y = 0.5,
  font.size = 2.5
) +
  scale_fill_gradient(
  low = "#cef99c",
  high = "#2f6d4d",
  na.value = "grey80",
  name = "Gene presence"
)

# 12. Save
ggsave(output_pdf, p2, width = 16, height = 22)
ggsave(output_png, p2, width = 16, height = 22, dpi = 300)

cat("Saved:\n")
cat(output_pdf, "\n")
cat(output_png, "\n")
