#!/bin/bash

# This code downloads ABRicate to Screen all strain genomes against the target genes 

# Outputs:
#   raw_outputs/abricate/                      - Raw per-strain ABRicate TSVs
#   outputs/abricate/                          - Clean summaries for each run
#   outputs/GENE_MATCHING_RESULTS.md           - Single report with both runs
#   outputs/abricate/TRACES.log                - Timestamped execution trace



# Preparation: define key variables for directories and parameters.
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

  # Build one combined database so this run reports the shared target set as a single summary.
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

    # Keep only the highest-identity hit for each strain/gene pair so repeated matches do not duplicate rows.
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

target_label_from_file() {
  local target_file="$1"
  local target_base

  # Use the FASTA filename as the gene label so the output stays specific to each target sequence.
  target_base="$(basename "${target_file}")"
  target_base="${target_base%.fasta}"
  echo "${target_base// /_}"
}

run_abricate_target_gene_screening() {
  local run_name="$1"
  local output_suffix="$2"
  shift 2
  local target_files=("$@")
  local summary_tmp="${OUT_DIR}/strain_gene_matches_${output_suffix}.tmp"
  local final_summary="${OUT_DIR}/strain_gene_matches_${output_suffix}.tsv"

  log_event ""
  log_event "=== ${run_name} ==="

  # Write the same clean header used by the combined run.
  echo -e "strain\tgene\tcontig\tstart\tend\tstrand\tcoverage_map\tgaps\tpct_coverage\tpct_identity" > "${summary_tmp}"

  for target_file in "${target_files[@]}"; do
    local gene_name db_name db_dir

    if [ ! -f "${target_file}" ]; then
      log_event "ERROR: target gene file not found: ${target_file}"
      exit 1
    fi

    gene_name="$(target_label_from_file "${target_file}")"
    db_name="target_gene_${gene_name}"
    db_dir="${DB_ROOT_DIR}/${db_name}"

    # Each FASTA gets its own ABRicate database so the exported gene column is preserved per target.
    mkdir -p "${db_dir}"
    cp "${target_file}" "${db_dir}/sequences"
    log_event "Found target file: $(basename "${target_file}")"
  done

  # Register the per-target databases before screening the strains.
  micromamba run -n "${ENV_NAME}" abricate --setupdb --datadir "${DB_ROOT_DIR}" >/dev/null

  local processed=0
  for target_file in "${target_files[@]}"; do
    local gene_name db_name raw_hits

    gene_name="$(target_label_from_file "${target_file}")"
    db_name="target_gene_${gene_name}"

    for strain_file in "${strain_files[@]}"; do
      processed=$((processed + 1))
      local strain_base strain_name safe_name raw_file

      strain_base="$(basename "${strain_file}")"
      strain_name="${strain_base%.fna}"
      strain_name="${strain_name%_GCA_*}"
      safe_name="${strain_name// /_}"
      raw_file="${RAW_DIR}/${safe_name}_${gene_name}_${output_suffix}_raw.tsv"

      micromamba run -n "${ENV_NAME}" abricate \
        --datadir "${DB_ROOT_DIR}" \
        --db "${db_name}" \
        --minid "${MIN_ID}" \
        --mincov "${MIN_COV}" \
        "${strain_file}" \
        > "${raw_file}"

      # Collapse multiple hits to the best identity for this exact strain/gene pair.
      raw_hits=$(awk -F $'\t' -v strain="${strain_name}" -v gene="${gene_name}" 'BEGIN { OFS="\t" }
        NR == 1 { next }
        {
          key = strain SUBSEP gene
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
        log_event "Processed ${processed}/${#strain_files[@]} strain-target combinations"
      fi
    done
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

## Input Data
- **Total strains screened**: ${#strain_files[@]}
- **Matching method**: ABRicate with ${MIN_ID}% minid, ${MIN_COV}% mincov

EOF
}

# Append a section to the report for each run
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

  # First run: combined target set icaA,icaR,mecA,sdrG 
  
  run_abricate_screening \
    "FULL GENE SET" \
    "target_genes_all" \
    "all_genes" \
    "${TARGET_DIR}/icaA.fasta" \
    "${TARGET_DIR}/icaR.fasta" \
    "${TARGET_DIR}/mecA.fasta" \
    "${TARGET_DIR}/sdrG.fasta"

  # Second run: icaA didn't work in the first so i redid a run only on the operon 
  run_abricate_screening \
    "ICA OPERON ONLY" \
    "target_genes_ica" \
    "ica_operon" \
    "${TARGET_DIR}/ica operon.fasta"

  # CLEAN SUMMARY : The clean summary didn't output in the first run so run just to put all the raw outputs in two one clean file
  run_abricate_target_gene_screening \
    "TARGET GENE SUMMARY BY INDIVIDUAL FASTA" \
    "target_genes_specific" \
    "${TARGET_DIR}/icaA.fasta" \
    "${TARGET_DIR}/icaR.fasta" \
    "${TARGET_DIR}/mecA.fasta" \
    "${TARGET_DIR}/sdrG.fasta"

  append_run_section \
    "Full Gene Set Results" \
    "${OUT_DIR}/strain_gene_matches_all_genes.tsv" \
    "This run screens against the partial icaA sequence plus icaR, mecA, and sdrG."

  append_run_section \
    "ICA Operon Results" \
    "${OUT_DIR}/strain_gene_matches_ica_operon.tsv" \
    "This run screens against the full ica operon sequence."

  append_run_section \
    "Individual Target Gene Results" \
    "${OUT_DIR}/strain_gene_matches_target_genes_specific.tsv" \
    "This run screens each target gene FASTA separately so the gene column stays specific to icaA, icaR, mecA, and sdrG."

  # CLEANED MERGE FROM RAWS: aggregate all raw ABRicate outputs into one cleaned file
  # containing only: strain, gene, contig, start, end, strand, coverage_map, gaps, pct_coverage, pct_identity
  combined_out="${OUT_DIR}/strain_gene_matches_from_raws.tsv"
  tmp_all="${OUT_DIR}/.all_raw_lines.tmp"
  : > "${tmp_all}"
  for f in "${RAW_DIR}"/*_raw.tsv; do
    [ -f "${f}" ] || continue
    # remove header lines beginning with '#'
    grep -v '^#' "${f}" >> "${tmp_all}"
  done
  if [ -s "${tmp_all}" ]; then
    awk -F"\t" 'BEGIN { OFS="\t" }
    {
      file=$1; contig=$2; start=$3; end=$4; strand=$5; gene_acc=$6; cov=$7; covmap=$8; gaps=$9; pct_cov=$10; pct_id=$11; db=$12; accession=$13; product=$14
      n=split(file, parts, "/"); fname=parts[n]
      strain=fname
      sub(/\.fna$/, "", strain)
      sub(/_GCA_.*/, "", strain)
      gsub(/ /, "_", strain)
      gene_label=""
      if (product ~ /\([^)]+\)/) { match(product, /\(([^)]+)\)/, m); gene_label = m[1] }
      else if (accession != "") { gene_label = accession }
      else { gene_label = gene_acc }
      key = strain SUBSEP gene_label
      if (!(key in best) || (pct_id+0) > (best[key]+0)) {
        best[key] = pct_id+0
        contig_k[key] = contig
        start_k[key] = start
        end_k[key] = end
        strand_k[key] = strand
        cov_k[key] = cov
        gaps_k[key] = gaps
        pctcov_k[key] = pct_cov
        pctid_k[key] = pct_id
      }
    }
    END {
      print "strain\tgene\tcontig\tstart\tend\tstrand\tcoverage\tgaps\tpct_coverage\tpct_identity"
      for (k in best) { split(k, parts, SUBSEP); print parts[1], parts[2], contig_k[k], start_k[k], end_k[k], strand_k[k], cov_k[k], gaps_k[k], pctcov_k[k], pctid_k[k] }
    }' "${tmp_all}" | sort -k1,1 -k2,2 > "${combined_out}"
    rm -f "${tmp_all}"
    log_event "Created cleaned merged file from raw outputs: ${combined_out}"
  else
    rm -f "${tmp_all}" 2>/dev/null || true
    log_event "No raw ABRicate files found to merge into ${combined_out}"
  fi

  {
    echo "## Output Files"
    echo
    echo "- Raw reports: ${RAW_DIR}"
    echo "- Full gene summary: ${OUT_DIR}/strain_gene_matches_all_genes.tsv"
    echo "- ICA operon summary: ${OUT_DIR}/strain_gene_matches_ica_operon.tsv"
    echo "- Individual target gene summary: ${OUT_DIR}/strain_gene_matches_target_genes_specific.tsv"
    echo "- Cleaned merged from raw outputs: ${OUT_DIR}/strain_gene_matches_from_raws.tsv"
    echo "- Trace log: ${TRACE_LOG}"
  } >> "${REPORT_FILE}"

  log_event "Workflow complete"
  log_event "Report updated: ${REPORT_FILE}"
}

main "$@"