#!/usr/bin/env python3
"""First bioinformatics script"""

def main():
    dna = "ATGCGATCGTAGCTA"
    gc = (dna.count('G') + dna.count('C')) / len(dna) * 100
    print(f"Sequence: {dna}")
    print(f"Length: {len(dna)} bp")
    print(f"GC content: {gc:.1f}%")

if __name__ == "__main__":
    main()
    