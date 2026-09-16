# High-Throughput Genomic Ingestion

A reproducible Bash pipeline for discovering and retrieving public sequencing data from the NCBI Sequence Read Archive (SRA).

This project uses the 2014 Ebola outbreak BioProject `PRJNA257197` as a case study. It automates SRA metadata retrieval with NCBI Entrez Direct, validates required command-line dependencies, extracts sequencing run identifiers, and downloads a controlled subset of paired-end FASTQ data for downstream bioinformatics analysis.

## Project: Automated SRA Metadata Discovery and Sequence Retrieval

**Focus areas:** Bash scripting, public biological databases, metadata parsing, reproducible research workflows, FASTQ ingestion, defensive shell programming.

## Motivation

Modern genomic studies often publish raw sequencing data in repositories such as the NCBI Sequence Read Archive rather than embedding the underlying data directly in a research paper.

Reproducing or extending a published analysis therefore requires more than downloading a single file. A researcher may need to:

- locate the correct BioProject,
- identify all associated sequencing runs,
- inspect platform and layout metadata,
- retrieve the appropriate run IDs,
- download raw reads in the correct paired-end structure,
- and ensure that failures do not silently propagate through the workflow.

This project automates that ingestion stage using the Ebola outbreak BioProject `PRJNA257197`.

## Biological Context

The dataset originates from genomic surveillance of the 2014 Ebola virus outbreak.

The project report identified **891 sequencing runs** associated with BioProject `PRJNA257197`. The retrieved metadata includes information such as sequencing platform, read layout, and run identifiers, which are needed before downstream quality control, alignment, and variant analysis can begin.

## Pipeline Workflow

```text
BioProject accession
        |
        v
NCBI SRA search
  esearch
        |
        v
Run metadata retrieval
  efetch -format runinfo
        |
        v
CSV metadata table
        |
        v
AWK run-ID extraction
        |
        v
Controlled run subset
        |
        v
fastq-dump --split-files
        |
        v
Paired FASTQ files
