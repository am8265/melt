#!/usr/bin/env bash

##############################################
#   MELT Single-Mode Wrapper (WGS MEI)       #
#   Author: Ayan Malakar                     #
#   Description:                             #
#     Automates running MELT (Mobile Element #
#     Locator Tool) Single mode on WGS BAMs  #
#     for MEI discovery (hg19 / hg38).       #
##############################################

set -euo pipefail

##### Usage statement
usage(){
cat <<EOF
  usage: $(basename "$0") bam ref cov read_len mean_is MELT_DIR RUN_DIR REF_VER

  Author: Ayan Malakar

  Description:
    Wrapper to run MELT (Mobile Element Locator Tool) in Single mode for
    mobile element insertion (MEI) discovery on WGS BAMs. Supports hg19 and hg38.

  Positional arguments (all required):
    bam        Full path to mapped BAM file (bam.bai required)
    ref        Full path to reference FASTA
    cov        Approximate nucleotide coverage of BAM file (e.g. 30 for 30X)
    read_len   Mean read length of library (e.g. 151)
    mean_is    Mean insert size of library
    MELT_DIR   Full path to MELT install directory
    RUN_DIR    Full path to directory for MELT output
    REF_VER    Reference version (19|38)

  Optional environment variables:
    JVM_MAX_MEM      Max Java heap size for MELT (default: 12G)
    MIN_CHR_LENGTH   Min chromosome length for MELT -d (default: 40000000)
EOF
}

##### Args parsing and validation
if [[ "$#" -eq 0 ]]; then
  usage
  exit 0
elif [[ "$#" -lt 8 ]]; then
  echo "At least one of the required parameters is not properly set by the given command:"
  temp_args="$@"
  echo "$0 ${temp_args}"
  exit 1
fi

JVM_MAX_MEM=${JVM_MAX_MEM:-12G}
MIN_CHR_LENGTH=${MIN_CHR_LENGTH:-40000000}

bam=$1
ref=$2
cov=$3
read_len=$4
mean_is=$5
MELT_DIR=$6
RUN_DIR=$7
REF_VER=$8

##### Check for required input (unset or empty)
if [[ -z "${bam}" || -z "${ref}" || -z "${cov}" || -z "${read_len}" || -z "${mean_is}" \
   || -z "${MELT_DIR}" || -z "${RUN_DIR}" || -z "${REF_VER}" ]]; then
  echo "At least one of the required parameters is not properly set by the given command:"
  temp_args="$@"
  echo "$0 ${temp_args}"
  exit 1
fi

##### Basic file/directory checks
if [[ ! -f "${bam}" ]]; then
  echo "Provided bam file doesn't exist: ${bam}" >&2
  exit 1
elif [[ ! -f "${bam}.bai" ]]; then
  echo "Provided bam file doesn't have accompanying index file: ${bam}.bai" >&2
  exit 1
elif [[ ! -f "${ref}" ]]; then
  echo "Provided reference file doesn't exist: ${ref}" >&2
  exit 1
elif [[ ! -d "${MELT_DIR}" ]]; then
  echo "Provided MELT directory doesn't exist: ${MELT_DIR}" >&2
  exit 1
elif [[ ! -f "${MELT_DIR}/MELT.jar" ]]; then
  echo "MELT.jar not found in MELT_DIR: ${MELT_DIR}/MELT.jar" >&2
  exit 1
fi

##### Floor coverage value, read length, and insert size to integers
cov=$( echo "${cov}" | cut -f1 -d\. )
read_len=$( echo "${read_len}" | cut -f1 -d\. )
mean_is=$( echo "${mean_is}" | cut -f1 -d\. )

##### remove trailing slash just to make sure
RUN_DIR="${RUN_DIR%/}"
MELT_DIR="${MELT_DIR%/}"

##### Create output directory (needed before writing files there)
mkdir -p "${RUN_DIR}"

##### Logging helper
LOG_FILE="${RUN_DIR}/ayan_melt_wrapper.log"
log() {
  local ts
  ts=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[$ts] $*" | tee -a "${LOG_FILE}"
}

log "Starting MELT Single run"
log "BAM: ${bam}"
log "Reference: ${ref}"
log "Coverage: ${cov}X, Read length: ${read_len}, Mean insert size: ${mean_is}"
log "MELT_DIR: ${MELT_DIR}"
log "RUN_DIR: ${RUN_DIR}"
log "REF_VER: ${REF_VER}"

##### Create transposons reference list and gene BED based on reference version
TRANS_LIST="${RUN_DIR}/transposon_reference.list"

if [[ "${REF_VER}" == "38" ]]; then
  ls "${MELT_DIR}"/me_refs/Hg38/*.zip > "${TRANS_LIST}"
  GENE_BED_FILE="${MELT_DIR}/add_bed_files/Hg38/Hg38.genes.bed"
elif [[ "${REF_VER}" == "19" ]]; then
  ls "${MELT_DIR}"/me_refs/1KGP_Hg19/*.zip > "${TRANS_LIST}"
  GENE_BED_FILE="${MELT_DIR}/add_bed_files/1KGP_Hg19/hg19.genes.bed"
else
  echo "ERROR: REF_VER must be 19 or 38 (got '${REF_VER}')" >&2
  exit 1
fi

if [[ ! -f "${GENE_BED_FILE}" ]]; then
  echo "Gene BED file not found: ${GENE_BED_FILE}" >&2
  exit 1
fi

log "Transposon reference list written to: ${TRANS_LIST}"
log "Gene BED file: ${GENE_BED_FILE}"

cd "${RUN_DIR}"

##### Run MELT Single locally
log "Running MELT Single locally."

java -Xmx"${JVM_MAX_MEM}" \
  -jar "${MELT_DIR}/MELT.jar" \
  Single \
  -bamfile "${bam}" \
  -h "${ref}" \
  -c "${cov}" \
  -r "${read_len}" \
  -e "${mean_is}" \
  -d "${MIN_CHR_LENGTH}" \
  -t "${TRANS_LIST}" \
  -n "${GENE_BED_FILE}" \
  -w "${RUN_DIR}"

log "MELT Single run completed successfully."
