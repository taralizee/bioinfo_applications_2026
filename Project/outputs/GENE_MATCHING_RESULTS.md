# Gene Matching Results Summary

## Execution Status
✅ **Script completed successfully** on 2026-05-13

## Input Data
- **Total strains screened**: 120
- **Target genes**: icaA (partial), icaR, mecA, sdrG, ica operon (full)
- **Matching method**: ABRicate with 90% minid, 80% mincov thresholds
- **Name normalization**: Strain names with spaces (e.g., "MRSE 52-2") converted to underscores for consistency

## Results Overview

### Overall Statistics
- **Strains with gene hits**: 115 / 120 (95.8%)
- **Strains WITHOUT gene hits**: 5
  - HESS022
  - I6-23.1
  - I6-23.2
  - NGS-ED-1109
  - SE57

### Gene Detection Frequency
| Gene | Accession | Hits | %Strains |
|------|-----------|------|----------|
| sdrG | AF245042 | 115 | 95.8% |
| mecA | KF415244 | 47 | 39.2% |
| icaR | AY138959 | 44 | 36.7% |
| ica operon | U43366.1 | 43 | 35.8% |
| icaA (partial) | U43366.1 | 0 | 0.0% |

**Note**: icaA was extracted as a partial sequence (1239 bp, bases 761..1999) from the larger ica operon. This may be the reason for poor detection. Consider using the full icaR sequence instead.

## Output Files

### Raw ABRicate Reports
- **Location**: `Project/raw_outputs/abricate/`
- **Format**: Individual TSV files per strain (`{strain}_targets_raw.tsv`)
- **Content**: Detailed hit information including:
  - SEQUENCE (contig ID)
  - START/END positions
  - STRAND (orientation)
  - GENE (reference accession)
  - COVERAGE (coverage map and gaps)
  - %COVERAGE and %IDENTITY

### Clean Summary
- **File**: `Project/outputs/abricate/strain_gene_matches.tsv`
- **Format**: TSV with columns: strain, gene, contig, start, end, strand, coverage_map, gaps, pct_coverage, pct_identity
- **Rows**: 115 (one row per strain with hits)

## Key Findings

1. **sdrG is ubiquitous** - found in 95.8% of strains, suggesting it's essential for S. epidermidis
2. **mecA is common** - found in ~40% of strains, indicating MRSE prevalence
3. **icaR is related to mecA** - similar distribution (~37%), likely related to biofilm/virulence pathway
4. **icaA was not detected** - the partial sequence extract may not be suitable for gene screening

## Recommendations

1. Replace icaA with the full ica operon sequence if available
2. Consider clustering strains by gene content pattern
3. Investigate the 5 strains without any target genes for evolutionary divergence
4. Use raw reports for detailed analysis of gene sequences, identity, and coverage


## ICA Operon Results

This run screens against the full ica operon sequence.

- **Strains with hits**: 44 / 120
- **Total hit rows**: 44

### Output File
- /home/ba-student3/bioinfo_applications_2026/Project/outputs/abricate/strain_gene_matches_ica_operon.tsv
