# Build a 16s ribsomial RNA phylogentic tree 

Aim : 
- Use helper program micromamba --version
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



esearch	--> searches the NCBI database
-db nucleotide	--> specifies the nucleotide database
-query -->	the search term
efetch	--> retrieves the sequence
-format fasta --> outputs the sequence in FASTA format

