-- =====================================================================
-- analysis.sql
--
-- setup.sql 実行後、SnowsightのWorksheetで上から順に実行することで
-- マルチオミクス解析の入口を体験できます。
-- =====================================================================

USE DATABASE MULTIOMICS_HANDSON;
USE SCHEMA PUBLIC;
USE WAREHOUSE HANDSON_WH;

-- ---------------------------------------------------------------------
-- 1. 各テーブルの中身確認
-- ---------------------------------------------------------------------
SELECT * FROM samples;
SELECT * FROM gene_expression_subset    LIMIT 20;
SELECT * FROM protein_expression_subset LIMIT 20;
SELECT * FROM drug_response_subset      LIMIT 20;
SELECT * FROM compounds;
SELECT * FROM compound_targets;

-- ---------------------------------------------------------------------
-- 2. 遺伝子発現とタンパク質発現をJOINして並べる
--    （mRNA量とタンパク量は必ずしも一致しない）
-- ---------------------------------------------------------------------
SELECT
  s.cell_line_name,
  g.gene_symbol,
  g.tpm                AS mrna_tpm,
  p.protein_abundance  AS protein_level,
  ROUND(p.protein_abundance - g.tpm, 2) AS protein_minus_mrna
FROM samples s
JOIN gene_expression_subset g
  ON s.sample_id = g.sample_id
JOIN protein_expression_subset p
  ON s.sample_id = p.sample_id
 AND g.gene_symbol = p.protein_symbol
ORDER BY s.cell_line_name, g.gene_symbol;

-- ---------------------------------------------------------------------
-- 3. EGFR発現・EGFRタンパク質量・Erlotinib/Gefitinib感受性
-- ---------------------------------------------------------------------
SELECT
  v.cell_line_name,
  v.cancer_type,
  v.gene_symbol,
  v.tpm,
  v.protein_abundance,
  v.drug_name,
  v.ic50_um,
  v.response_label
FROM multiomics_drug_response_view v
WHERE v.gene_symbol = 'EGFR'
  AND v.drug_name IN ('Erlotinib', 'Gefitinib')
ORDER BY v.ic50_um ASC;

-- ---------------------------------------------------------------------
-- 4. ABCB1発現・Doxorubicin感受性
--    （ABCB1高発現は薬剤耐性に関与すると古典的に知られる）
-- ---------------------------------------------------------------------
SELECT
  v.cell_line_name,
  v.cancer_type,
  v.gene_symbol,
  v.tpm,
  v.protein_abundance,
  v.drug_name,
  v.ic50_um,
  v.response_label
FROM multiomics_drug_response_view v
WHERE v.gene_symbol = 'ABCB1'
  AND v.drug_name = 'Doxorubicin'
ORDER BY v.tpm DESC;

-- ---------------------------------------------------------------------
-- 5. がん種ごとの薬剤感受性集計
-- ---------------------------------------------------------------------
SELECT
  cancer_type,
  drug_name,
  ROUND(AVG(ic50_um), 3) AS avg_ic50_um,
  ROUND(AVG(auc), 3)     AS avg_auc,
  COUNT(*)               AS n_samples
FROM multiomics_drug_response_view
GROUP BY cancer_type, drug_name
ORDER BY cancer_type, avg_ic50_um;

-- ---------------------------------------------------------------------
-- 6. 遺伝子ごとの response_label 別 平均発現量
-- ---------------------------------------------------------------------
SELECT
  gene_symbol,
  response_label,
  ROUND(AVG(tpm), 2)               AS avg_tpm,
  ROUND(AVG(protein_abundance), 2) AS avg_protein,
  COUNT(*)                         AS n_rows
FROM multiomics_drug_response_view
GROUP BY gene_symbol, response_label
ORDER BY gene_symbol, response_label;

-- ---------------------------------------------------------------------
-- 7. 候補薬剤抽出（Sensitive な組み合わせを IC50 昇順で）
-- ---------------------------------------------------------------------
SELECT
  cell_line_name,
  cancer_type,
  gene_symbol,
  tpm,
  protein_abundance,
  drug_id,
  drug_name,
  ic50_um,
  response_label
FROM multiomics_drug_response_view
WHERE response_label = 'Sensitive'
ORDER BY ic50_um ASC;

-- ---------------------------------------------------------------------
-- 8. 候補薬剤に SMILES と標的情報を付与
-- ---------------------------------------------------------------------
SELECT
  v.cell_line_name,
  v.cancer_type,
  v.gene_symbol,
  v.tpm,
  v.protein_abundance,
  v.drug_id,
  v.drug_name,
  v.ic50_um,
  v.response_label,
  c.chembl_id,
  c.pubchem_cid,
  c.canonical_smiles,
  t.target_symbol,
  t.target_name
FROM multiomics_drug_response_view v
JOIN compounds c
  ON v.drug_id = c.drug_id
LEFT JOIN compound_targets t
  ON v.drug_id = t.drug_id
WHERE v.response_label = 'Sensitive'
ORDER BY v.ic50_um ASC;
