# Build a 16s rRNA phylogentic tree 

Aim : 
- Download and Use programs to build Tree 
- Download sequences from NCBI 
- Build and visualise a simple phylogentic tree 

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
An environment is a separate workspace that contains the specific software and versions needed for a project so they don’t interfere with other programs on the system.  
For the rest of this work we will need to activate this environment

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
*awk* --> text-processing tool that reads input records, applies pattern-based rules, and performs actions like filtering, extracting columns, and reformatting output  

```bash
# First ckeck you are in the right directory to create you folder in 
cd /home/ba-student3/bioinfo_applications_2026/tutorials

# Upload sequences into a new file 

# Run these commands inside the activated conda-sars environment
micromamba activate conda-sars # To be able to use EDirect

esearch -db nucleotide -query "Escherichia coli[Organism] AND 16S ribosomal RNA AND 1200:2000[Sequence Length]" | efetch -format fasta | awk 'BEGIN{RS=">"; ORS=""} NR==2{print ">"$0}' > all_16s.fasta #tells awk to treat each FASTA entry as one record separated by >, then output only record 2 (the first real sequence, since record 1 is empty before the first >) and prepend > so the result stays valid FASTA.

esearch -db nucleotide -query "Salmonella enterica[Organism] AND 16S ribosomal RNA AND 1200:2000[Sequence Length]" | efetch -format fasta | awk 'BEGIN{RS=">"; ORS=""} NR==2{print ">"$0}' >> all_16s.fasta

esearch -db nucleotide -query "Klebsiella pneumoniae[Organism] AND 16S ribosomal RNA AND 1200:2000[Sequence Length]" | efetch -format fasta | awk 'BEGIN{RS=">"; ORS=""} NR==2{print ">"$0}' >> all_16s.fasta

esearch -db nucleotide -query "Bacillus subtilis[Organism] AND 16S ribosomal RNA AND 1200:2000[Sequence Length]" | efetch -format fasta | awk 'BEGIN{RS=">"; ORS=""} NR==2{print ">"$0}' >> all_16s.fasta

esearch -db nucleotide -query "Staphylococcus aureus[Organism] AND 16S ribosomal RNA AND 1200:2000[Sequence Length]" | efetch -format fasta | awk 'BEGIN{RS=">"; ORS=""} NR==2{print ">"$0}' >> all_16s.fasta

esearch -db nucleotide -query "Lactobacillus casei[Organism] AND 16S ribosomal RNA AND 1200:2000[Sequence Length]" | efetch -format fasta | awk 'BEGIN{RS=">"; ORS=""} NR==2{print ">"$0}' >> all_16s.fasta
```

# Step 3 : Align sequences 
Our fasta sequences are now in one folder but they are not aligned 

## Install all Programs needed to Align, Check and Build the Tree 

```bash
micromamba activate conda-sars # so our programs are all in the same environment
micromamba install -n conda-sars -c conda-forge -c bioconda -y mafft clipkit raxml

# Verify if tools are installed 
micromamba activate conda-sars
which mafft 
which clipkit 
which raxmlHPC 
# If you get a return = installed 
```

## Align sequences 
```bash
# align sequences in new file
micromamba activate conda-sars
cd tutorials 
mafft --auto --thread 2 all_16s.fasta > all_16s_aligned.fasta # automatically choose an alignement strategy and thread 2 mean it uses 2 CPU to align 

# check of the output file
head -n 20 all_16s_aligned.fasta # only 20 first lines 
```
What is a thread?  
A thread is an independent stream of work inside a program, so multiple threads let the program run parts of a task at the same time.  
In practice, the thread number often matches how many CPU cores (CPU = Central Processing Unit) are used in parallel.  
More threads can make a job faster, but on a shared server you should use a reasonable number so you do not take all resources. 

## Check alignment with ClipKIT
To be extra cautious with our alignment, we use ClipKIT to remove sites with too many gaps.

ClipKIt works by reading aligned sequences column by column and check wether the position is useful for phylogeny or if it's noise. smart-gap mode applies rules to keep informative sites and remove highly gappy sites.

```bash
# remove highly gapped sites from the alignment
clipkit all_16s_aligned.fasta -m smart-gap -o all_16s_aligned.clipkit.fasta  
# runs clipkit on our aligned file  
# -m smart gaps = mode option : remove columns with too many gaps  
# -o file name = output option  

# Check output
head -n 20 all_16s_aligned.clipkit.fasta
```

# Step 4 : Build Tree 
We use RAxML to build a maximum likelihood phylogenetic tree from the trimmed alignment.

-s  : input alignment (ClipKIT trimmed)  
-m  : substitution model (GTRCAT = fast, good for 16S)   
(mathematical rule RAxML uses to estimate how DNA bases (A, C, G, T) change over evolutionary time when building the tree)  
-p  : random seed (for reproducibility)
(starting number for the computer’s random choices)  
-n  : name of the output files  
-T  : number of CPU threads  

```bash
# build the phylogenetic tree
raxmlHPC-PTHREADS --no-seq-check -s all_16s_aligned.clipkit.fasta -m GTRCAT -p 1234719872 -n 16S_tree -T 2 #raxmlHPC-PTHREADS is the multi-threaded(multi-CPU) RAxML executable and no-seq-check tells RAxML to skip its strict validation step before running.

# check output files created by RAxML
ls RAxML_*16S_tree* # created 5 files you can view with list 
```
Multiple files with different output  
bestTree = Best Tree  
result = all candidates Trees  
parsimony = initially tree build by parsimmony  
Log = Step-by-step optimization log(improvement over time)  
Info = all info (runtime, model...)  

# Step 5 : Visualise Tree using R 
Switch to R to visualise Phylogenetic tree 

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
tree.rooted <- root(tree, outgroup = "PZ049809.1") # rooted tree 

# modify tree tip labels to show organism names
tree.df <- data.frame(label = tree.rooted$tip.label) # create data frame containing all labels from the rooted tree 

tree.df[grepl("PV810134", tree.df$label), "new_label"] <- "Escherichia coli"
tree.df[grepl("PZ049817", tree.df$label), "new_label"] <- "Klebsiella pneumoniae"
tree.df[grepl("PZ049809", tree.df$label), "new_label"] <- "Bacillus subtilis"
tree.df[grepl("PZ050804", tree.df$label), "new_label"] <- "Staphylococcus aureus"
tree.df[grepl("PX998450", tree.df$label), "new_label"] <- "Lacticaseibacillus casei"
tree.df[grepl("PZ054617", tree.df$label), "new_label"] <- "Salmonella enterica"
# add new_label columm to df 
# grepl = checks for pattern in tree.df$label and returns TRUE when found
# when grepl return TRUE the new_label value is selected 


# replace the labels in the tree
final.tree <- rename_taxa(tree.rooted, tree.df, label, new_label) # rename_taxa(..., label, new_label): tells R to match each current tip label in label and replace it with the corresponding value in new_label.

# visualize the tree
ggtree(final.tree) +
  geom_treescale() + # adds branch lenght scale
  geom_tiplab(aes(color = label), size = 5) + #writes tip label
  geom_tippoint(size = 2, fill = "white", color = "black") #adds point at each end 

# save to PDF
ggsave("16S_rRNA_tree.pdf", height = 15, width = 15)
```
