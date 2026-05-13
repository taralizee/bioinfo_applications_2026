#!/bin/bash

################################################################################
# GENE MATCHING WORKFLOW
#
# Purpose: Screen all strain genomes against two target sets with ABRicate:
#   1. Full set: icaA partial, icaR, mecA, sdrG
#   2. ica operon only: the full operon sequence
# 
# The script runs two independent searches so you can compare the target sets
# in the final report without needing a separate comparison table:
#   1. Full set: partial icaA, icaR, mecA, sdrG
#   2. ica operon only: the full operon sequence
#
# Outputs:
#   raw_outputs/abricate/                      - Raw per-strain ABRicate TSVs
#   outputs/abricate/                          - Clean summaries for each run
#   outputs/GENE_MATCHING_RESULTS.md           - Single report with both runs
#   outputs/abricate/TRACES.log                - Timestamped execution trace
#
################################################################################

set -euo pipefail

ENV_NAME="project_bioinfo"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${PROJECT_DIR}/data/target_sequences"
STRAIN_DIR="${PROJECT_DIR}/data/sequences_annotations/fasta"
DB_ROOT_DIR="${PROJECT_DIR}/data/abricate_db"
RAW_DIR="${PROJECT_DIR}/raw_outputs/abricate"
OUT_DIR="${PROJECT_DIR}/outputs/abricate"
REPORT_FILE="${PROJECT_DIR}/outputs/GENE_MATCHING_RESULTS.md"
TRACE_LOG="${OUT_DIR}/TRACES.log"

MIN_ID="${MIN_ID:-90}"
MIN_COV="${MIN_COV:-80}"

log_event() {
  local message="$1"
  local timestamp
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[${timestamp}] ${message}" | tee -a "${TRACE_LOG}"
}

# Ensure the shared bioinformatics environment exists and has the tools needed
# for downloading databases and running ABRicate.
ensure_environment() {
  if ! command -v micromamba >/dev/null 2>&1; then
    log_event "ERROR: micromamba is required but was not found."
    exit 1
  fi

  if ! micromamba env list | awk 'NR>2{print $1}' | grep -qx "${ENV_NAME}"; then
    log_event "Creating micromamba environment: ${ENV_NAME}"
    micromamba create -y -n "${ENV_NAME}" -c conda-forge -c bioconda ncbi-datasets-cli
  fi

  if ! micromamba run -n "${ENV_NAME}" sh -lc 'command -v abricate >/dev/null 2>&1'; then
    log_event "Installing ABRicate and BLAST into ${ENV_NAME}"
    micromamba install -y -n "${ENV_NAME}" -c conda-forge -c bioconda abricate blast
  fi
}

prepare_workspace() {
  if [ ! -d "${STRAIN_DIR}" ]; then
    log_event "ERROR: strain FASTA folder not found: ${STRAIN_DIR}"
    exit 1
  fi

# Make sure the input strains exist and create the output directories that will
# hold raw ABRicate reports, cleaned summaries, the database, and the trace log.
  mkdir -p "${PROJECT_DIR}/outputs" "${RAW_DIR}" "${OUT_DIR}" "${DB_ROOT_DIR}"
  : > "${TRACE_LOG}"
}

count_target_records() {
  grep -c '^>' "$1"
}

run_abricate_screening() {
  local run_name="$1"
  local db_name="$2"
  local output_suffix="$3"
  shift 3
  local target_files=("$@")
  local db_dir="${DB_ROOT_DIR}/${db_name}"
  local summary_tmp="${OUT_DIR}/strain_gene_matches_${output_suffix}.tmp"
  local final_summary="${OUT_DIR}/strain_gene_matches_${output_suffix}.tsv"

  mkdir -p "${db_dir}"

  log_event ""
  log_event "=== ${run_name} ==="

  for target_file in "${target_files[@]}"; do
    if [ ! -f "${target_file}" ]; then
      log_event "ERROR: target gene file not found: ${target_file}"
      exit 1
    fi
    log_event "Found target file: $(basename "${target_file}")"
  done

  cat "${target_files[@]}" > "${db_dir}/sequences"
  log_event "Database sequences: $(count_target_records "${db_dir}/sequences")"

  micromamba run -n "${ENV_NAME}" abricate --setupdb --datadir "${DB_ROOT_DIR}" >/dev/null

  echo -e "strain\tgene\tcontig\tstart\tend\tstrand\tcoverage_map\tgaps\tpct_coverage\tpct_identity" > "${summary_tmp}"

  local processed=0
  for strain_file in "${strain_files[@]}"; do
    processed=$((processed + 1))
    local strain_base strain_name safe_name raw_file raw_hits
    strain_base="$(basename "${strain_file}")"
    strain_name="${strain_base%.fna}"
    strain_name="${strain_name%_GCA_*}"
    safe_name="${strain_name// /_}"
    raw_file="${RAW_DIR}/${safe_name}_${output_suffix}_raw.tsv"

    # Confirm the target sequences exist before building the database.
    micromamba run -n "${ENV_NAME}" abricate \
      --datadir "${DB_ROOT_DIR}" \
      --db "${db_name}" \
      --minid "${MIN_ID}" \
      --mincov "${MIN_COV}" \
      "${strain_file}" \
      > "${raw_file}"

    # Keep only the highest-identity hit for each strain/gene pair.
    raw_hits=$(awk -F $'\t' -v strain="${strain_name}" 'BEGIN { OFS="\t" }
      NR == 1 { next }
      {
        key = strain SUBSEP $12
        if (!(key in best) || $11 > best[key]) {
          best[key] = $11
          contig[key] = $2
          start[key] = $3
          end[key] = $4
          strand[key] = $5
          coverage_map[key] = $8
          gaps[key] = $9
          pct_cov[key] = $10
          pct_id[key] = $11
        }
      }
      END {
        for (key in best) {
          split(key, parts, SUBSEP)
          print parts[1], parts[2], contig[key], start[key], end[key], strand[key], coverage_map[key], gaps[key], pct_cov[key], pct_id[key]
        }
      }' "${raw_file}" 2>/dev/null || true)

    if [ -n "${raw_hits}" ]; then
      printf '%s\n' "${raw_hits}" >> "${summary_tmp}"
    fi

    if (( processed % 20 == 0 )); then
      log_event "Processed ${processed}/${#strain_files[@]} strains"
    fi
  done

  {
    head -n 1 "${summary_tmp}"
    tail -n +2 "${summary_tmp}" | sort -k1,1 -k2,2
  } > "${final_summary}"

  rm -f "${summary_tmp}"
  log_event "Summary written: ${final_summary}"
}

write_report_header() {
  cat > "${REPORT_FILE}" <<EOF
# Gene Matching Results Summary

## Execution Status
✅ Workflow completed on $(date '+%Y-%m-%d')

## Input Data
- **Total strains screened**: ${#strain_files[@]}
- **Matching method**: ABRicate with ${MIN_ID}% minid, ${MIN_COV}% mincov

EOF
}

append_run_section() {
  local title="$1"
  local summary_file="$2"
  local description="$3"

  local total_strains hit_rows
  total_strains=$(tail -n +2 "${summary_file}" | cut -f1 | sort -u | wc -l | tr -d ' ')
  hit_rows=$(tail -n +2 "${summary_file}" | wc -l | tr -d ' ')

  {
    echo "## ${title}"
    echo
    echo "${description}"
    echo
    echo "- **Strains with hits**: ${total_strains} / ${#strain_files[@]}"
    echo "- **Total hit rows**: ${hit_rows}"
    echo
    echo "### Target Frequency"
    echo "| Target | Hits | %Strains |"
    echo "|--------|------|----------|"
    tail -n +2 "${summary_file}" \
      | cut -f2 \
      | sort \
      | uniq -c \
      | awk -v total="${#strain_files[@]}" '{printf "| %s | %s | %.1f%% |\n", $2, $1, ($1/total)*100}'
    echo
    echo "### Output File"
    echo "- ${summary_file}"
    echo
  } >> "${REPORT_FILE}"
}

main() {
  # Set up tools and clean workspace state before starting any searches.
  ensure_environment
  prepare_workspace

  log_event "=== GENE MATCHING WORKFLOW STARTED ==="
  log_event "Project directory: ${PROJECT_DIR}"

  # Collect every strain FASTA once and reuse the list for both runs.
  shopt -s nullglob
  strain_files=("${STRAIN_DIR}"/*.fna)
  if [ ${#strain_files[@]} -eq 0 ]; then
    log_event "ERROR: no strain FASTA files found in ${STRAIN_DIR}"
    exit 1
  fi

  strain_names=()
  for strain_file in "${strain_files[@]}"; do
    strain_base="$(basename "${strain_file}")"
    strain_name="${strain_base%.fna}"
    strain_names+=("${strain_name%_GCA_*}")
  done

  log_event "Found ${#strain_files[@]} strain genome files"

  write_report_header

  run_abricate_screening \
    "FULL GENE SET" \
    "target_genes_all" \
    "all_genes" \
    "${TARGET_DIR}/icaA.fasta" \
    "${TARGET_DIR}/icaR.fasta" \
    "${TARGET_DIR}/mecA.fasta" \
    "${TARGET_DIR}/sdrG.fasta"

  run_abricate_screening \
    "ICA OPERON ONLY" \
    "target_genes_ica" \
    "ica_operon" \
    "${TARGET_DIR}/ica operon.fasta"

  append_run_section \
    "Full Gene Set Results" \
    "${OUT_DIR}/strain_gene_matches_all_genes.tsv" \
    "This run screens against the partial icaA sequence plus icaR, mecA, and sdrG."

  append_run_section \
    "ICA Operon Results" \
    "${OUT_DIR}/strain_gene_matches_ica_operon.tsv" \
    "This run screens against the full ica operon sequence."

  {
    echo "## Output Files"
    echo
    echo "- Raw reports: ${RAW_DIR}"
    echo "- Full gene summary: ${OUT_DIR}/strain_gene_matches_all_genes.tsv"
    echo "- ICA operon summary: ${OUT_DIR}/strain_gene_matches_ica_operon.tsv"
    echo "- Trace log: ${TRACE_LOG}"
  } >> "${REPORT_FILE}"

  log_event "Workflow complete"
  log_event "Report updated: ${REPORT_FILE}"
}

main "$@"