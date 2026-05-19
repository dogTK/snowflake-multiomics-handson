# Data Sources and License Notes

This handson dataset is inspired by public life science data resources such as ChEMBL and DepMap/CCLE.

The dataset included in this repository is a **simplified subset created for technical demonstration and educational purposes**. It is not the original data, and it should not be used to draw biomedical or clinical conclusions.

## What this dataset is

- Small, hand-curated sample rows for a handful of cell lines (HepG2, Huh7, A549, MCF7, HT29)
- A small set of genes and proteins (EGFR, ERBB2, ABCB1, MGAT5, FUT8, TP53, KRAS)
- A small set of compounds (Erlotinib, Doxorubicin, Gefitinib, Lapatinib) with illustrative SMILES, ChEMBL ID, PubChem CID values
- Values for TPM, protein abundance, IC50, and AUC are set so that the relationships demonstrated in the article (e.g. EGFR high → EGFR inhibitor sensitive, ABCB1 high → Doxorubicin resistant) are easy to observe.

## What this dataset is NOT

- It is **not** a direct export of ChEMBL, DepMap, CCLE, or any other public database.
- It is **not** suitable for biomedical research, target validation, or drug repositioning.
- The numeric values (TPM, protein abundance, IC50, AUC) are illustrative and **do not** represent any specific experiment.

## Sources of inspiration

The schema, identifiers, and types of relationships are inspired by the following public resources. Please refer to each provider for license and usage terms.

- ChEMBL
  - https://www.ebi.ac.uk/chembl/
- DepMap Portal
  - https://depmap.org/portal/
- CCLE (Cancer Cell Line Encyclopedia)
  - https://sites.broadinstitute.org/ccle/
- PubChem
  - https://pubchem.ncbi.nlm.nih.gov/

When you use real data from these resources for actual research or production workloads, always check the latest license terms of the original data provider.

## License of this repository

The code, SQL, and Markdown materials in this repository are provided for educational use. Do not infer any specific license from individual files; refer to the repository-level `LICENSE` file if one is provided. In the absence of one, please contact the author before redistributing or using the content commercially.

## Disclaimer

The content of this repository is provided "as is", without warranty of any kind. The author is not responsible for any consequences arising from the use of this material, including but not limited to scientific, medical, regulatory, or financial outcomes.
