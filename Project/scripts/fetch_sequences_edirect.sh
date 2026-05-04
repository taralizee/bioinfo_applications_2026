#!/usr/bin/env bash
set -euo pipefail
# Usage: bash fetch_sequences_edirect.sh download_candidates_chosen.csv ../../sequences/
CSV_IN="${1:-download_candidates_chosen.csv}"
OUTDIR="${2:-../../sequences}"
mkdir -p "$OUTDIR"
if [ ! -f "$CSV_IN" ]; then
  echo "CSV with chosen_id not found: $CSV_IN" >&2
  exit 2
fi

tail -n +2 "$CSV_IN" | while IFS="," read -r Strain accession type candidate_ids candidate_titles chosen_id; do
  # remove surrounding quotes from fields if present
  chosen_id=$(echo "$chosen_id" | sed 's/^"//;s/"$//')
  Strain=$(echo "$Strain" | sed 's/^"//;s/"$//')
  if [ -z "$chosen_id" ]; then
    echo "Skipping $Strain (no chosen_id)"
    continue
  fi
  outfn="$OUTDIR/${Strain}.fasta"
  echo "Fetching for $Strain -> $outfn"
  if [[ "$chosen_id" =~ ^[0-9]+$ ]]; then
    # numeric -> assume nuccore ID
    efetch -db nuccore -id "$chosen_id" -format fasta > "$outfn"
  elif [[ "$chosen_id" =~ ^GCA_|^GCF_ ]]; then
    # assembly accession -> link to nuccore then fetch
    esearch -db assembly -query "$chosen_id" | elink -target nuccore | efetch -format fasta > "$outfn"
  else
    # otherwise assume accession or nucleotide id
    efetch -db nucleotide -id "$chosen_id" -format fasta > "$outfn" || {
      # fallback: try nuccore
      efetch -db nuccore -id "$chosen_id" -format fasta > "$outfn"
    }
  fi
done

echo "Done. Sequences saved in $OUTDIR"
