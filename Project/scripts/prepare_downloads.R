#!/usr/bin/env Rscript
# Prepare NCBI download candidates using EDirect
args <- commandArgs(trailingOnly=TRUE)
csv_in <- ifelse(length(args)>=1, args[1], "Strains_cleaned.csv")
out_csv <- ifelse(length(args)>=2, args[2], "download_candidates.csv")
auto_select <- FALSE

if(!file.exists(csv_in)) stop("Input CSV not found: ", csv_in)

df <- read.csv(csv_in, sep=";", stringsAsFactors = FALSE)
# Use full paths to EDirect tools from conda-project environment
ESEARCH <- "/home/ba-student3/micromamba/envs/conda-project/bin/esearch"
EFETCH <- "/home/ba-student3/micromamba/envs/conda-project/bin/efetch"
XTRACT <- "/home/ba-student3/micromamba/envs/conda-project/bin/xtract"

get_candidates_for_bioproject <- function(bioproj, strain){
  # query nuccore docsum and extract Id and Title
  cmd <- sprintf('%s -db nuccore -query "%%s[BioProject]" | %s -format docsum | %s -pattern DocumentSummary -element Id Title', ESEARCH, EFETCH, XTRACT)
  cmd <- sprintf(cmd, bioproj)
  out <- tryCatch(system(cmd, intern=TRUE), error=function(e) character(0))
  if(length(out)==0) return(data.frame(Id=character(0), Title=character(0), stringsAsFactors=FALSE))
  parts <- strsplit(out, "\t")
  ids <- vapply(parts, `[`, FUN.VALUE=character(1), 1)
  titles <- vapply(parts, function(x) if(length(x)>=2) x[2] else "", FUN.VALUE=character(1))
  data.frame(Id=ids, Title=titles, stringsAsFactors=FALSE)
}

results <- data.frame(Strain=character(0), accession=character(0), type=character(0), candidate_ids=character(0), candidate_titles=character(0), chosen_id=character(0), stringsAsFactors=FALSE)
for(i in seq_len(nrow(df))){
  strain <- df$Strain[i]
  acc <- df$accession.number[i]
  if(is.na(acc) || acc==""){
    results[nrow(results)+1,] <- list(strain, acc, "none", "", "", "")
    next
  }
  if(grepl('^PRJ', acc, ignore.case=TRUE)){
    cand <- get_candidates_for_bioproject(acc, strain)
    if(nrow(cand)==0){
      results[nrow(results)+1,] <- list(strain, acc, "bioproject", "", "", "")
    } else {
      # try to filter by strain name in title (case-insensitive)
      match_idx <- grepl(strain, cand$Title, ignore.case=TRUE)
      if(sum(match_idx)==0){
        cids <- paste(cand$Id, collapse=",")
        ctitles <- paste(cand$Title, collapse='||')
        results[nrow(results)+1,] <- list(strain, acc, "bioproject", cids, ctitles, "")
      } else if(sum(match_idx)==1){
        chosen <- cand$Id[which(match_idx)[1]]
        cids <- paste(cand$Id, collapse=",")
        ctitles <- paste(cand$Title, collapse='||')
        chosen <- if(auto_select) chosen else ""
        results[nrow(results)+1,] <- list(strain, acc, "bioproject", cids, ctitles, chosen)
      } else {
        cids <- paste(cand$Id, collapse=",")
        ctitles <- paste(cand$Title, collapse='||')
        results[nrow(results)+1,] <- list(strain, acc, "bioproject", cids, ctitles, "")
      }
    }
  } else {
    # treat as direct accession/assembly id
    results[nrow(results)+1,] <- list(strain, acc, "accession", acc, "", acc)
  }
}

write.csv(results, out_csv, row.names=FALSE, quote=TRUE)
cat(sprintf("Wrote %d candidate rows to %s\n", nrow(results), out_csv))
cat("Now open the CSV to inspect and (optionally) fill the 'chosen_id' column for each strain.\n")
