-- =====================================================================
-- setup.sql
--
-- Snowflake Trial Account の Worksheet に貼り付けて実行するだけで、
-- マルチオミクスハンズオン用のデータベース、スキーマ、ウェアハウス、
-- テーブル、サンプルデータ、統合ビューが作成されます。
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Database / Schema / Warehouse の作成
-- ---------------------------------------------------------------------
CREATE OR REPLACE DATABASE MULTIOMICS_HANDSON;
CREATE OR REPLACE SCHEMA MULTIOMICS_HANDSON.PUBLIC;

CREATE OR REPLACE WAREHOUSE HANDSON_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

USE DATABASE MULTIOMICS_HANDSON;
USE SCHEMA PUBLIC;
USE WAREHOUSE HANDSON_WH;

-- ---------------------------------------------------------------------
-- 2. Table 作成
-- ---------------------------------------------------------------------

-- 2.1 samples: 細胞株・サンプルのメタデータ
CREATE OR REPLACE TABLE samples (
  sample_id         STRING,
  cell_line_name    STRING,
  cancer_type       STRING,
  tissue            STRING,
  primary_disease   STRING,
  mutation_summary  STRING
);

-- 2.2 gene_expression_subset: サンプル×遺伝子のmRNA発現量
CREATE OR REPLACE TABLE gene_expression_subset (
  sample_id    STRING,
  gene_symbol  STRING,
  tpm          FLOAT
);

-- 2.3 protein_expression_subset: サンプル×タンパク質の発現量
CREATE OR REPLACE TABLE protein_expression_subset (
  sample_id          STRING,
  protein_symbol     STRING,
  protein_abundance  FLOAT
);

-- 2.4 drug_response_subset: サンプル×薬剤の感受性
CREATE OR REPLACE TABLE drug_response_subset (
  sample_id       STRING,
  drug_id         STRING,
  drug_name       STRING,
  ic50_um         FLOAT,
  auc             FLOAT,
  response_label  STRING
);

-- 2.5 compounds: 化合物情報
CREATE OR REPLACE TABLE compounds (
  drug_id           STRING,
  drug_name         STRING,
  chembl_id         STRING,
  pubchem_cid       STRING,
  canonical_smiles  STRING,
  molecular_weight  FLOAT,
  alogp             FLOAT
);

-- 2.6 compound_targets: 化合物と標的の対応
CREATE OR REPLACE TABLE compound_targets (
  drug_id            STRING,
  drug_name          STRING,
  target_symbol      STRING,
  target_name        STRING,
  target_chembl_id   STRING,
  relationship       STRING
);

-- ---------------------------------------------------------------------
-- 3. サンプルデータ投入
-- ---------------------------------------------------------------------

-- 3.1 samples
INSERT INTO samples
  (sample_id, cell_line_name, cancer_type, tissue, primary_disease, mutation_summary)
VALUES
  ('S001', 'HepG2', 'Liver Cancer',  'Liver',  'Hepatocellular Carcinoma',  'TP53 mut'),
  ('S002', 'Huh7',  'Liver Cancer',  'Liver',  'Hepatocellular Carcinoma',  'TP53 mut'),
  ('S003', 'A549',  'Lung Cancer',   'Lung',   'NSCLC',                     'KRAS G12S mut'),
  ('S004', 'MCF7',  'Breast Cancer', 'Breast', 'Breast Adenocarcinoma',     'PIK3CA mut'),
  ('S005', 'HT29',  'Colon Cancer',  'Colon',  'Colorectal Adenocarcinoma', 'BRAF V600E mut');

-- 3.2 gene_expression_subset
INSERT INTO gene_expression_subset
  (sample_id, gene_symbol, tpm)
VALUES
  -- HepG2
  ('S001', 'EGFR',  10.2),
  ('S001', 'ERBB2', 11.5),
  ('S001', 'ABCB1',  3.2),
  ('S001', 'MGAT5',  5.0),
  ('S001', 'FUT8',  11.0),
  ('S001', 'TP53',  18.0),
  ('S001', 'KRAS',  22.0),
  -- Huh7 (ABCB1 high)
  ('S002', 'EGFR',   5.5),
  ('S002', 'ERBB2',  9.5),
  ('S002', 'ABCB1', 32.0),
  ('S002', 'MGAT5',  6.0),
  ('S002', 'FUT8',  13.0),
  ('S002', 'TP53',  22.0),
  ('S002', 'KRAS',  19.0),
  -- A549 (EGFR high, KRAS high)
  ('S003', 'EGFR',  45.0),
  ('S003', 'ERBB2',  8.0),
  ('S003', 'ABCB1',  5.0),
  ('S003', 'MGAT5', 14.0),
  ('S003', 'FUT8',  20.0),
  ('S003', 'TP53',  12.0),
  ('S003', 'KRAS',  55.0),
  -- MCF7 (ERBB2 high)
  ('S004', 'EGFR',   8.0),
  ('S004', 'ERBB2', 40.0),
  ('S004', 'ABCB1',  2.5),
  ('S004', 'MGAT5',  8.0),
  ('S004', 'FUT8',   9.5),
  ('S004', 'TP53',  25.0),
  ('S004', 'KRAS',  18.0),
  -- HT29 (EGFR moderate-high)
  ('S005', 'EGFR',  22.0),
  ('S005', 'ERBB2', 15.0),
  ('S005', 'ABCB1',  6.0),
  ('S005', 'MGAT5', 11.0),
  ('S005', 'FUT8',  14.0),
  ('S005', 'TP53',  20.0),
  ('S005', 'KRAS',  28.0);

-- 3.3 protein_expression_subset (mRNAと完全相関しないように調整)
INSERT INTO protein_expression_subset
  (sample_id, protein_symbol, protein_abundance)
VALUES
  -- HepG2
  ('S001', 'EGFR',   8.0),
  ('S001', 'ERBB2', 14.0),
  ('S001', 'ABCB1',  4.0),
  ('S001', 'MGAT5',  6.5),
  ('S001', 'FUT8',  13.0),
  ('S001', 'TP53',  22.0),
  ('S001', 'KRAS',  20.0),
  -- Huh7
  ('S002', 'EGFR',  12.0),  -- mRNAは低いがタンパクは中程度（mRNA-protein乖離）
  ('S002', 'ERBB2', 10.0),
  ('S002', 'ABCB1', 35.0),
  ('S002', 'MGAT5',  7.5),
  ('S002', 'FUT8',  12.5),
  ('S002', 'TP53',  24.0),
  ('S002', 'KRAS',  17.5),
  -- A549
  ('S003', 'EGFR',  52.0),
  ('S003', 'ERBB2',  9.0),
  ('S003', 'ABCB1',  6.0),
  ('S003', 'MGAT5', 16.0),
  ('S003', 'FUT8',  22.0),
  ('S003', 'TP53',  11.0),
  ('S003', 'KRAS',  50.0),
  -- MCF7
  ('S004', 'EGFR',   6.0),
  ('S004', 'ERBB2', 42.0),
  ('S004', 'ABCB1',  3.0),
  ('S004', 'MGAT5',  9.0),
  ('S004', 'FUT8',  10.0),
  ('S004', 'TP53',  26.0),
  ('S004', 'KRAS',  18.5),
  -- HT29
  ('S005', 'EGFR',  18.0),
  ('S005', 'ERBB2', 16.0),
  ('S005', 'ABCB1',  7.5),
  ('S005', 'MGAT5', 12.0),
  ('S005', 'FUT8',  15.0),
  ('S005', 'TP53',  18.0),
  ('S005', 'KRAS',  26.0);

-- 3.4 drug_response_subset
INSERT INTO drug_response_subset
  (sample_id, drug_id, drug_name, ic50_um, auc, response_label)
VALUES
  -- HepG2
  ('S001', 'DRUG001', 'Erlotinib',    4.0,  0.55, 'Intermediate'),
  ('S001', 'DRUG002', 'Doxorubicin',  0.5,  0.28, 'Sensitive'),
  ('S001', 'DRUG003', 'Gefitinib',    4.5,  0.58, 'Intermediate'),
  ('S001', 'DRUG004', 'Lapatinib',    4.0,  0.55, 'Intermediate'),
  -- Huh7 (ABCB1 high → Doxorubicin resistant)
  ('S002', 'DRUG001', 'Erlotinib',    9.5,  0.78, 'Resistant'),
  ('S002', 'DRUG002', 'Doxorubicin', 15.0,  0.88, 'Resistant'),
  ('S002', 'DRUG003', 'Gefitinib',   10.0,  0.80, 'Resistant'),
  ('S002', 'DRUG004', 'Lapatinib',    9.0,  0.76, 'Resistant'),
  -- A549 (EGFR high → EGFR inhibitors sensitive)
  ('S003', 'DRUG001', 'Erlotinib',    0.8,  0.18, 'Sensitive'),
  ('S003', 'DRUG002', 'Doxorubicin',  1.0,  0.30, 'Sensitive'),
  ('S003', 'DRUG003', 'Gefitinib',    0.9,  0.20, 'Sensitive'),
  ('S003', 'DRUG004', 'Lapatinib',    2.5,  0.42, 'Intermediate'),
  -- MCF7 (ERBB2 high → Lapatinib sensitive)
  ('S004', 'DRUG001', 'Erlotinib',    5.5,  0.62, 'Intermediate'),
  ('S004', 'DRUG002', 'Doxorubicin',  0.4,  0.25, 'Sensitive'),
  ('S004', 'DRUG003', 'Gefitinib',    6.0,  0.65, 'Intermediate'),
  ('S004', 'DRUG004', 'Lapatinib',    0.6,  0.18, 'Sensitive'),
  -- HT29
  ('S005', 'DRUG001', 'Erlotinib',    2.0,  0.38, 'Sensitive'),
  ('S005', 'DRUG002', 'Doxorubicin',  0.8,  0.30, 'Sensitive'),
  ('S005', 'DRUG003', 'Gefitinib',    2.5,  0.42, 'Sensitive'),
  ('S005', 'DRUG004', 'Lapatinib',    3.5,  0.50, 'Intermediate');

-- 3.5 compounds
INSERT INTO compounds
  (drug_id, drug_name, chembl_id, pubchem_cid, canonical_smiles, molecular_weight, alogp)
VALUES
  ('DRUG001', 'Erlotinib',   'CHEMBL553',   '176870', 'COCCOc1cc2ncnc(Nc3cccc(Cl)c3)c2cc1OCCOC',                                                                       393.4, 2.7),
  ('DRUG002', 'Doxorubicin', 'CHEMBL53463', '31703',  'COc1cccc2c1C(=O)c1c(O)c3c(c(O)c1C2=O)CC(O)(C(=O)CO)CC3OC1CC(N)C(O)C(C)O1',                                       543.5, 1.3),
  ('DRUG003', 'Gefitinib',   'CHEMBL939',   '123631', 'COc1cc2ncnc(Nc3ccc(F)c(Cl)c3)c2cc1OCCCN1CCOCC1',                                                                446.9, 3.7),
  ('DRUG004', 'Lapatinib',   'CHEMBL554',   '208908', 'CS(=O)(=O)CCNCc1ccc(-c2ccc3ncnc(Nc4ccc(OCc5cccc(F)c5)c(Cl)c4)c3c2)o1',                                          581.1, 5.4);

-- 3.6 compound_targets
INSERT INTO compound_targets
  (drug_id, drug_name, target_symbol, target_name, target_chembl_id, relationship)
VALUES
  ('DRUG001', 'Erlotinib',   'EGFR',  'Epidermal growth factor receptor',          'CHEMBL203',  'primary'),
  ('DRUG002', 'Doxorubicin', 'TOP2A', 'DNA topoisomerase 2-alpha',                 'CHEMBL1806', 'primary'),
  ('DRUG003', 'Gefitinib',   'EGFR',  'Epidermal growth factor receptor',          'CHEMBL203',  'primary'),
  ('DRUG004', 'Lapatinib',   'EGFR',  'Epidermal growth factor receptor',          'CHEMBL203',  'primary'),
  ('DRUG004', 'Lapatinib',   'ERBB2', 'Receptor tyrosine-protein kinase erbB-2',   'CHEMBL1824', 'primary');

-- ---------------------------------------------------------------------
-- 4. 統合 View 作成
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW multiomics_drug_response_view AS
SELECT
  s.sample_id,
  s.cell_line_name,
  s.cancer_type,
  s.tissue,
  s.primary_disease,
  s.mutation_summary,
  g.gene_symbol,
  g.tpm,
  p.protein_abundance,
  d.drug_id,
  d.drug_name,
  d.ic50_um,
  d.auc,
  d.response_label
FROM samples s
JOIN gene_expression_subset g
  ON s.sample_id = g.sample_id
JOIN protein_expression_subset p
  ON s.sample_id = p.sample_id
 AND g.gene_symbol = p.protein_symbol
JOIN drug_response_subset d
  ON s.sample_id = d.sample_id;

-- ---------------------------------------------------------------------
-- 5. セットアップ完了確認
-- ---------------------------------------------------------------------
SELECT 'setup completed' AS status;

SELECT COUNT(*) AS samples_count               FROM samples;
SELECT COUNT(*) AS gene_expression_count       FROM gene_expression_subset;
SELECT COUNT(*) AS protein_expression_count    FROM protein_expression_subset;
SELECT COUNT(*) AS drug_response_count         FROM drug_response_subset;
SELECT COUNT(*) AS compounds_count             FROM compounds;
SELECT COUNT(*) AS compound_targets_count      FROM compound_targets;
SELECT COUNT(*) AS multiomics_view_row_count   FROM multiomics_drug_response_view;
