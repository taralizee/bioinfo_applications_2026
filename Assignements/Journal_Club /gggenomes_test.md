
# Test of gggenomes
Link to gggnomes github : https://thackl.github.io/gggenomes/index.html 

```r
install.packages("gggenomes") 
library(gggenomes)

data(package="gggenomes") # list of of dataset exemples 

gggenomes(
  genes = emale_genes, seqs = emale_seqs, links = emale_ava,
  feats = list(emale_tirs, ngaros=emale_ngaros, gc=emale_gc)) |> 
  add_sublinks(emale_prot_ava) |>
  sync() + # synchronize genome directions based on links
  geom_feat(position="identity", size=6) +
  geom_seq() +
  geom_link(data=links(2)) +
  geom_bin_label() +
  geom_gene(aes(fill=name)) +
  geom_gene_tag(aes(label=name), nudge_y=0.1, check_overlap = TRUE) +
  geom_feat(data=feats(ngaros), alpha=.3, size=10, position="identity") +
  geom_feat_note(aes(label="Ngaro-transposon"), data=feats(ngaros),
      nudge_y=.1, vjust=0) +
  geom_wiggle(aes(z=score, linetype="GC-content"), feats(gc),
      fill="lavenderblush4", position=position_nudge(y=-.2), height = .2) +
  scale_fill_brewer("Genes", palette="Dark2", na.value="cornsilk3")


setwd("/home/ba-student3/bioinfo_applications_2026/Journal_Club ") # added line to save png in journal club file 
ggsave("emales.png", width=8, height=4)
```
