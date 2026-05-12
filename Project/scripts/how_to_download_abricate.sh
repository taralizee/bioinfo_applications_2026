#!/bin/bash

# Install ABRicate and related tools in the shared project environment.
# This script is meant as a copyable reference for the project setup.

set -euo pipefail

ENV_NAME="project_bioinfo"

echo "Creating or updating micromamba environment: ${ENV_NAME}"

if ! command -v micromamba >/dev/null 2>&1; then
  echo "ERROR: micromamba is required but was not found."
  exit 1
fi

if micromamba env list | awk 'NR>2{print $1}' | grep -qx "${ENV_NAME}"; then
  micromamba install -y -n "${ENV_NAME}" -c conda-forge -c bioconda ncbi-datasets-cli blast abricate entrez-direct
else
  micromamba create -y -n "${ENV_NAME}" -c conda-forge -c bioconda ncbi-datasets-cli blast abricate entrez-direct
fi

echo
echo "Verifying installed tools"
micromamba run -n "${ENV_NAME}" datasets version
micromamba run -n "${ENV_NAME}" blastn -version | head -n 1
micromamba run -n "${ENV_NAME}" abricate --version
micromamba run -n "${ENV_NAME}" esearch -version | head -n 1

echo
echo "Optional ABRicate database setup"
micromamba run -n "${ENV_NAME}" abricate --setupdb
micromamba run -n "${ENV_NAME}" abricate --list

echo
echo "Done. Use micromamba run -n ${ENV_NAME} <command> for project tools."