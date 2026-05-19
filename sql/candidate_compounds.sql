-- =====================================================================
-- candidate_compounds.sql
--
-- response_label = 'Sensitive' の薬剤を、SMILESおよび標的情報とともに
-- 抽出します。出力はそのまま RDKit / py3Dmol での構造可視化に渡せます。
-- =====================================================================

USE DATABASE MULTIOMICS_HANDSON;
USE SCHEMA PUBLIC;
USE WAREHOUSE HANDSON_WH;

-- ---------------------------------------------------------------------
-- 1. Sensitive な薬剤を IC50 昇順で抽出（最小構成）
-- ---------------------------------------------------------------------
SELECT
  sample_id,
  cell_line_name,
  cancer_type,
  gene_symbol,
  tpm,
  protein_abundance,
  drug_id,
  drug_name,
  ic50_um,
  auc,
  response_label
FROM multiomics_drug_response_view
WHERE response_label = 'Sensitive'
ORDER BY ic50_um ASC;

-- ---------------------------------------------------------------------
-- 2. SMILES と標的情報を付与（構造可視化に渡す最終形）
-- ---------------------------------------------------------------------
SELECT
  v.sample_id,
  v.cell_line_name,
  v.cancer_type,
  v.gene_symbol,
  v.tpm,
  v.protein_abundance,
  v.drug_id,
  v.drug_name,
  v.ic50_um,
  v.auc,
  v.response_label,
  c.chembl_id,
  c.pubchem_cid,
  c.canonical_smiles,
  c.molecular_weight,
  c.alogp,
  t.target_symbol,
  t.target_name,
  t.target_chembl_id
FROM multiomics_drug_response_view v
JOIN compounds c
  ON v.drug_id = c.drug_id
LEFT JOIN compound_targets t
  ON v.drug_id = t.drug_id
WHERE v.response_label = 'Sensitive'
ORDER BY v.ic50_um ASC;

-- ---------------------------------------------------------------------
-- 3. 薬剤ごとに「Sensitive細胞株数」「平均IC50」をランキング
-- ---------------------------------------------------------------------
SELECT
  v.drug_id,
  v.drug_name,
  c.chembl_id,
  c.pubchem_cid,
  c.canonical_smiles,
  COUNT(DISTINCT v.sample_id)         AS sensitive_sample_count,
  ROUND(AVG(v.ic50_um), 3)            AS avg_ic50_um,
  MIN(v.ic50_um)                      AS min_ic50_um,
  MAX(v.ic50_um)                      AS max_ic50_um
FROM multiomics_drug_response_view v
JOIN compounds c
  ON v.drug_id = c.drug_id
WHERE v.response_label = 'Sensitive'
GROUP BY v.drug_id, v.drug_name, c.chembl_id, c.pubchem_cid, c.canonical_smiles
ORDER BY sensitive_sample_count DESC, avg_ic50_um ASC;

-- ---------------------------------------------------------------------
-- 4. 「EGFR高発現 × EGFR標的薬」候補抽出
--    （標的とドライバ遺伝子の整合性を見る）
-- ---------------------------------------------------------------------
SELECT
  v.cell_line_name,
  v.cancer_type,
  v.gene_symbol,
  v.tpm,
  v.protein_abundance,
  v.drug_name,
  v.ic50_um,
  v.response_label,
  t.target_symbol,
  c.canonical_smiles
FROM multiomics_drug_response_view v
JOIN compound_targets t
  ON v.drug_id = t.drug_id
JOIN compounds c
  ON v.drug_id = c.drug_id
WHERE v.gene_symbol = 'EGFR'
  AND t.target_symbol = 'EGFR'
  AND v.tpm >= 20             -- EGFR高発現の閾値（教材用）
ORDER BY v.ic50_um ASC;
