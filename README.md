# `run_MELT_2.2.2.sh`

This Bash script automates running **MELT v2.2.2 (Mobile Element Locator Tool)** to detect **mobile element insertions (MEIs)** in whole-genome sequencing (WGS) data.
It validates input files, configures genome build–specific resources (hg19 or hg38), and executes MELT’s *Single* mode with consistent parameters and logging.

---

## Tools Used

- **Java (MELT.jar)** – core engine for MEI detection
- **BWA-aligned BAM**, **reference FASTA**, and **BED annotation files** – input data resources

---

## Motivation

Running MELT manually for each WGS sample was **time-consuming and error-prone**.
This script standardized input handling, added validation and logging, and enabled **reproducible, large-scale MEI discovery** across multiple genomes.

---

*(Author: Ayan Malakar)*