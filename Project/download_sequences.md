# Download NCBI Sequences Guide

This folder contains scripts to reliably download sequences for strains listed in `Strains_cleaned.csv` using EDirect. The workflow has 3 steps: prepare, inspect, and fetch.

## Setup: Install EDirect

If you haven't already, create a conda environment with EDirect:

```bash
micromamba create -n conda-project
micromamba activate conda-project
micromamba install perl-io-socket-ssl perl-net-ssleay perl-lwp-protocol-https entrez-direct
which esearch  # verify it works
```

## Workflow

### Step 1: Prepare candidate sequences (run R script)

From the `Project/` directory:

```bash
cd Project
Rscript scripts/prepare_downloads.R Strains_cleaned.csv download_candidates.csv
```

**What happens:**
- Reads `Strains_cleaned.csv`
- For each row with a **BioProject** accession (e.g. `PRJNA559376`): queries NCBI and retrieves all nucleotide records in that project
- For each row with a **direct accession** (e.g. `GCA_011307695.1`): marks it as ready to fetch
- Writes `download_candidates.csv` with columns:
  - `Strain` — strain name
  - `accession` — original accession from input
  - `type` — `"bioproject"`, `"accession"`, or `"none"`
  - `candidate_ids` — comma-separated NCBI record IDs (for BioProject rows)
  - `candidate_titles` — NCBI sequence titles (for manual inspection)
  - `chosen_id` — **empty** (you fill this in next step)

### Step 2: Inspect and select sequences (manual step in R or spreadsheet)

Open `download_candidates.csv` in R or a spreadsheet editor. For each row:

1. Look at `candidate_titles` — these are the actual NCBI sequence names for that BioProject
2. Find the title that matches your strain name (e.g., "Staphylococcus epidermidis strain SESURV_p3_1362 chromosome")
3. Fill the `chosen_id` column with:
   - The **numeric ID** from `candidate_ids` that corresponds to that title, OR
   - A direct accession (already filled for non-BioProject rows)
4. Save the file as `download_candidates_chosen.csv`

**Example:**
```
Strain,accession,type,candidate_ids,candidate_titles,chosen_id
SESURV_p3_1362,PRJNA559376,bioproject,"12345,12346,12347","Staph aureus SESURV_p3 genome||Staph aureus other||...",12345
NIHLM003,GCA_000276165.1,accession,GCA_000276165.1,,GCA_000276165.1
```

### Step 3: Fetch sequences (run shell script)

From the `Project/scripts/` directory:

```bash
cd Project/scripts
bash fetch_sequences_edirect.sh ../download_candidates_chosen.csv ../../sequences/
```

**What happens:**
- Reads `download_candidates_chosen.csv`
- For each row with a `chosen_id`:
  - If it's a numeric ID → fetches from NCBI nuccore database
  - If it's a GCA_/GCF_ assembly accession → searches assembly DB and links to nucleotide records
  - If it's another accession → tries nucleotide DB with fallback to nuccore
- Writes FASTA files to `../../sequences/` named `{Strain}.fasta`

**Output:**
- Sequences saved in the `sequences/` folder at the repo root

## Notes

- **Strain name matching:** The preparer uses case-insensitive substring matching on NCBI titles. For short strain names (e.g., "SE35"), check titles carefully to avoid false matches.
- **Rate limiting:** NCBI may occasionally return 502 errors if requests are too frequent. The preparer will retry automatically.
- **Direct accessions:** Rows with GCA_/GCF_/accession numbers skip the BioProject query and use that accession directly.
- **Auto-selection:** The preparer leaves `chosen_id` blank for ambiguous cases. Set `auto_select <- TRUE` in `scripts/prepare_downloads.R` (line 5) to auto-fill when exactly one strain match is found.
