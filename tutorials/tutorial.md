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


