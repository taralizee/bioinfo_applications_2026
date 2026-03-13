# make sure you are in the tutorials folder
setwd("/home/ba-student3/bioinfo_applications_2026/tutorials")

# load the libraries
library("ape")
library("Biostrings")
library("ggplot2")
library("ggtree")
library(treeio)

# load the tree file
tree <- read.tree("RAxML_bestTree.16S_tree")

# define the root: Bacillus subtilis is most distantly related (Firmicutes)
tree.rooted <- root(tree, outgroup = "PZ049809.1")

# modify tree tip labels to show organism names
tree.df <- data.frame(label = tree.rooted$tip.label)

tree.df[grepl("PV810134", tree.df$label), "new_label"] <- "Escherichia coli"
tree.df[grepl("PZ049817", tree.df$label), "new_label"] <- "Klebsiella pneumoniae"
tree.df[grepl("PZ049809", tree.df$label), "new_label"] <- "Bacillus subtilis"
tree.df[grepl("PZ050804", tree.df$label), "new_label"] <- "Staphylococcus aureus"
tree.df[grepl("PX998450", tree.df$label), "new_label"] <- "Lacticaseibacillus casei"
tree.df[grepl("PZ054617", tree.df$label), "new_label"] <- "Salmonella enterica"

# replace the labels in the tree
final.tree <- rename_taxa(tree.rooted, tree.df, label, new_label)

# visualize the tree
# hexpand(0.5) adds 50% extra space on the right so long names are not cut off
ggtree(final.tree) +
  geom_treescale() +
  geom_tiplab(aes(color = label), size = 5) +
  geom_tippoint(size = 2, fill = "white", color = "black") +
  hexpand(0.5)

# save to PDF (wider to fit all names)
ggsave("16S_rRNA_tree.pdf", height = 15, width = 20)
