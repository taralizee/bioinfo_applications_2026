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



# Get frequency per type and significance

# =========================
# Load frequency table
# =========================

freq <- read_csv("Project/outputs/gene_frequency_by_type.csv",show_col_types = FALSE)

# Keep only commensal and pathogen
freq <- freq %>%
  filter(type %in% c("commensal", "pathogen"))

# =========================
# Fisher exact tests
# =========================

results <- freq %>%
  group_by(gene) %>%
  group_modify(~{

    # Extract values
    comm <- .x %>% filter(type == "commensal")
    path <- .x %>% filter(type == "pathogen")

    # Build contingency table
    matrix_test <- matrix(
      c(
        path$n_present,
        path$n_strains - path$n_present,

        comm$n_present,
        comm$n_strains - comm$n_present
      ),
      nrow = 2,
      byrow = TRUE
    )

    # Fisher test
    fisher_res <- fisher.test(matrix_test)

    # Return results
    tibble(
      pathogenic_present = path$n_present,
      pathogenic_absent = path$n_strains - path$n_present,

      commensal_present = comm$n_present,
      commensal_absent = comm$n_strains - comm$n_present,

      odds_ratio = fisher_res$estimate,
      p_value = fisher_res$p.value
    )
  }) %>%
  ungroup()

# =========================
# Adjust p-values
# =========================

results <- results %>%
  mutate(
    adjusted_p_value = p.adjust(p_value, method = "BH"),

    significance = case_when(
      adjusted_p_value < 0.001 ~ "***",
      adjusted_p_value < 0.01 ~ "**",
      adjusted_p_value < 0.05 ~ "*",
      TRUE ~ "ns"
    )
  )



print(results)

# Frenquency by surce and significance 

# =========================
# Load source frequency table
# =========================

freq_source <- read_csv(
  "Project/outputs/gene_frequency_by_source.csv",show_col_types = FALSE)

# Rename source column if needed
freq_source <- freq_source %>%
  rename(source = `Host source`)

# =========================
# Fisher tests by source
# =========================

all_sources <- unique(freq_source$source)

results_source <- map_dfr(all_sources, function(current_source) {

  # Compare ONE source vs all other sources combined
  source_data <- freq_source %>%
    mutate(group = ifelse(source == current_source,
                          current_source,
                          "Other"))

  # Summarise counts
  grouped <- source_data %>%
    group_by(group, gene) %>%
    summarise(
      n_strains = sum(n_strains),
      n_present = sum(n_present),
      .groups = "drop"
    )

  # Run Fisher test for each gene
  grouped %>%
    group_by(gene) %>%
    group_modify(~{

      target <- .x %>% filter(group == current_source)
      other  <- .x %>% filter(group == "Other")

      matrix_test <- matrix(
        c(
          target$n_present,
          target$n_strains - target$n_present,

          other$n_present,
          other$n_strains - other$n_present
        ),
        nrow = 2,
        byrow = TRUE
      )

      fisher_res <- fisher.test(matrix_test)

      tibble(
        source = current_source,

        source_present = target$n_present,
        source_absent = target$n_strains - target$n_present,

        other_present = other$n_present,
        other_absent = other$n_strains - other$n_present,

        odds_ratio = fisher_res$estimate,
        p_value = fisher_res$p.value
      )
    }) %>%
    ungroup()
})

# =========================
# Adjust p-values
# =========================

results_source <- results_source %>%
  mutate(
    adjusted_p_value = p.adjust(p_value, method = "BH"),

    significance = case_when(
      adjusted_p_value < 0.001 ~ "***",
      adjusted_p_value < 0.01 ~ "**",
      adjusted_p_value < 0.05 ~ "*",
      TRUE ~ "ns"
    )
  )



print(results_source)


