# OSIRIS
### Old Species Inference and Reconstruction from Incomplete Sequences

A modular aDNA reconstruction pipeline for extinct species.
Reconstructs partial or fragmented ancient genomes using the
closest living relative as a reference scaffold.

Named after the Egyptian god dismembered and reconstructed —
a fitting metaphor for genome reconstruction from fragments.

---

## Current run: Great Auk (*Pinguinus impennis*)
| | |
|---|---|
| Extinct | 1844, Eldey Island, Iceland |
| Sample | Last female ever killed |
| SRA | SRR32453835 |
| Reference | Razorbill (*Alca torda*), GCA_008658365.1 |
| Divergence | ~5% |

---

## Pipeline modules
| Module | Step | Tool |
|--------|------|------|
| 01 | Download — SRA reads + reference | sra-tools, ncbi-datasets |
| 02 | QC — trim and filter reads | fastp, fastqc |
| 03 | Damage — authenticate aDNA | mapDamage2 |
| 04 | Map — align to reference | bwa-mem2, samtools |
| 05 | Stats — coverage + gap finding | samtools, seqkit |
| 06 | Reconstruct — fill gaps | python, biopython |
| 07 | Annotate — genes + selection scan | python |
| 08 | Report — HTML summary | python, matplotlib |

---

## Usage
```bash
# Install environment
conda env create -f envs/osiris.yaml
conda activate osiris

# Configure your species in config/config.yaml
# then run modules in order:
bash modules/01_download.sh config/config.yaml
bash modules/02_qc.sh config/config.yaml
# ... and so on
```

---

## To run a different species
Edit only `config/config.yaml` — change species name, SRA accession,
and reference accession. All modules are fully generic.

---

## Requirements
- macOS (Apple Silicon) or Linux
- conda
- ~30 GB free disk space per species run
