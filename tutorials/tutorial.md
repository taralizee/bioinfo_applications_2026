# Build a 16s rRNA phylogentic tree 

Aim : 
- Use programs
- Download sequences from NCBI 
- Create a phylogentic tree 

## Step 1 : download a conda(micromamba) 
Program that install and manages other programms 
Either follow the steps or ask copilot 

```bash
# Create bin directory in your home if it doesn't exist permits to activate micromamba from anywhere 
mkdir -p ~/.local/bin

# Download and extract micromamba
cd ~/.local/bin
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba

# Move micromamba to the current directory
mv bin/micromamba ./
rmdir bin

# Initialize micromamba for your shell
./micromamba shell init -s bash --root-prefix ~/micromamba

# Reload your shell configuration
source ~/.bashrc

# Verify installation
micromamba --version

# Tell micromamba where to search for programs
micromamba config append channels defaults  
micromamba config append channels bioconda
micromamba config append channels conda-forge

# Create a new environment named conda-env : environment where you can install programs 
micromamba create -n conda-env

# Activate the environment
micromamba activate conda-env
```


## Step 2: Retrieve sequences from NCBI
To do that we will use the programm EDirect which allow us to search and find biological data from NCBI 

### Download EDirect using micromanba

```bash
micromamba create -n conda-sars # create a new environment 
micromamba activate conda-sars # activate said environment 
micromamba install perl-io-socket-ssl perl-net-ssleay perl-lwp-protocol-https entrez-direct # install EDirect 
esearch version # check if it worked
```

### Download sequences using EDirect 

*esearch*	--> searches the NCBI database  
*-db* --> in which data base to search in  
For example : protein, nucléotide, genome...  
*-query* --> the search term  
[Filter] ex. Escherichia coli[Organism]  
AND to add conditions  
NOT to exclude condition  
use filters to avoid wrong genes, partial sequences ...
*efetch*	--> retrieves the sequence  
*-format fasta* --> outputs the sequence in FASTA format  
*awk* --> returns only the first matching result  


```bash
# First ckeck you are in the right directory to create you folder in 
cd /home/ba-student3/bioinfo_applications_2026/tutorials

# Upload sequences into a new file 

# Run these commands inside the activated conda-sars environment
micromamba activate conda-sars

esearch -db nucleotide -query "Escherichia coli[Organism] AND 16S ribosomal RNA AND 1200:2000[Sequence Length]" | efetch -format fasta | awk 'BEGIN{RS=">"; ORS=""} NR==2{print ">"$0}' > all_16s.fasta

esearch -db nucleotide -query "Salmonella enterica[Organism] AND 16S ribosomal RNA AND 1200:2000[Sequence Length]" | efetch -format fasta | awk 'BEGIN{RS=">"; ORS=""} NR==2{print ">"$0}' >> all_16s.fasta

esearch -db nucleotide -query "Klebsiella pneumoniae[Organism] AND 16S ribosomal RNA AND 1200:2000[Sequence Length]" | efetch -format fasta | awk 'BEGIN{RS=">"; ORS=""} NR==2{print ">"$0}' >> all_16s.fasta

esearch -db nucleotide -query "Bacillus subtilis[Organism] AND 16S ribosomal RNA AND 1200:2000[Sequence Length]" | efetch -format fasta | awk 'BEGIN{RS=">"; ORS=""} NR==2{print ">"$0}' >> all_16s.fasta

esearch -db nucleotide -query "Staphylococcus aureus[Organism] AND 16S ribosomal RNA AND 1200:2000[Sequence Length]" | efetch -format fasta | awk 'BEGIN{RS=">"; ORS=""} NR==2{print ">"$0}' >> all_16s.fasta

esearch -db nucleotide -query "Lactobacillus casei[Organism] AND 16S ribosomal RNA AND 1200:2000[Sequence Length]" | efetch -format fasta | awk 'BEGIN{RS=">"; ORS=""} NR==2{print ">"$0}' >> all_16s.fasta
```

# Step 3 : Align sequences 
Our fasta sequences are now in one folder but they are not aligned 

## Install Program to align, check and tree 

```bash
micromamba activate conda-sars
micromamba install -n conda-sars -c conda-forge -c bioconda -y mafft clipkit raxml

# Verify if tools are installed 
mafft --version
clipkit -h | head
raxmlHPC -v
```

## Align sequences 
```bash
# align sequences in new file
micromamba activate conda-sars
cd tutorials
mafft --auto --thread 2 all_16s.fasta > all_16s_aligned.fasta

# check of the output file
head -n 20 all_16s_aligned.fasta
```

## Check alignment with ClipKIT
To be extra cautious with our alignment, we use ClipKIT to remove sites with too many gaps.

```bash
# remove highly gapped sites from the alignment
clipkit all_16s_aligned.fasta -m smart-gap -o all_16s_aligned.clipkit.fasta

# Check output
head -n 20 all_16s_aligned.clipkit.fasta
```

# Step 4 : Build Tree 

We use RAxML to build a maximum likelihood phylogenetic tree from the trimmed alignment.

```bash
# build the phylogenetic tree
# -s  : input alignment (ClipKIT trimmed)
# -m  : substitution model (GTRCAT = fast, good for 16S)
# -p  : random seed (reproducibility)
# -n  : name of the output files
# -T  : number of CPU threads (use 2 on shared server)
raxmlHPC-PTHREADS --no-seq-check -s all_16s_aligned.clipkit.fasta -m GTRCAT -p 1234719872 -n 16S_tree -T 2

# check output files created by RAxML
ls RAxML_*16S_tree*
```

# Step 5 : Visualise Tree using R 
Switch to r to visualise Phylogenetic tree 

```r
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
ggtree(final.tree) +
  geom_treescale() +
  geom_tiplab(aes(color = label), size = 5) +
  geom_tippoint(size = 2, fill = "white", color = "black")

# save to PDF
ggsave("16S_rRNA_tree.pdf", height = 15, width = 15)
```
