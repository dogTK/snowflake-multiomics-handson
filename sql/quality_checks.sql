-- =====================================================================
-- quality_checks.sql
--
-- 解析の前に必ず確認したいデータ品質チェック集です。
-- マルチオミクス解析ではサンプルIDの不整合や欠損が結果を破壊するため、
-- ここを飛ばさないでください。
-- =====================================================================

USE DATABASE MULTIOMICS_HANDSON;
USE SCHEMA PUBLIC;
USE WAREHOUSE HANDSON_WH;

-- ---------------------------------------------------------------------
-- 1. 各テーブルの行数
-- ---------------------------------------------------------------------
SELECT 'samples'                  AS table_name, COUNT(*) AS n FROM samples
UNION ALL
SELECT 'gene_expression_subset',     COUNT(*) FROM gene_expression_subset
UNION ALL
SELECT 'protein_expression_subset',  COUNT(*) FROM protein_expression_subset
UNION ALL
SELECT 'drug_response_subset',       COUNT(*) FROM drug_response_subset
UNION ALL
SELECT 'compounds',                  COUNT(*) FROM compounds
UNION ALL
SELECT 'compound_targets',           COUNT(*) FROM compound_targets;

-- ---------------------------------------------------------------------
-- 2. NULL チェック
-- ---------------------------------------------------------------------
SELECT 'samples.sample_id NULL'        AS check_name, COUNT(*) AS n
FROM samples WHERE sample_id IS NULL
UNION ALL
SELECT 'gene_expression_subset.sample_id NULL',  COUNT(*)
FROM gene_expression_subset WHERE sample_id IS NULL
UNION ALL
SELECT 'gene_expression_subset.tpm NULL',        COUNT(*)
FROM gene_expression_subset WHERE tpm IS NULL
UNION ALL
SELECT 'protein_expression_subset.sample_id NULL', COUNT(*)
FROM protein_expression_subset WHERE sample_id IS NULL
UNION ALL
SELECT 'protein_expression_subset.protein_abundance NULL', COUNT(*)
FROM protein_expression_subset WHERE protein_abundance IS NULL
UNION ALL
SELECT 'drug_response_subset.sample_id NULL',    COUNT(*)
FROM drug_response_subset WHERE sample_id IS NULL
UNION ALL
SELECT 'drug_response_subset.ic50_um NULL',      COUNT(*)
FROM drug_response_subset WHERE ic50_um IS NULL
UNION ALL
SELECT 'compounds.canonical_smiles NULL',        COUNT(*)
FROM compounds WHERE canonical_smiles IS NULL;

-- ---------------------------------------------------------------------
-- 3. 参照整合性（FK相当）チェック
--    各テーブルの sample_id / drug_id が、参照先に存在するか
-- ---------------------------------------------------------------------

-- 3.1 gene_expression_subset の sample_id が samples に存在するか
SELECT 'gene_expression_subset.sample_id NOT IN samples' AS check_name,
       sample_id
FROM (
  SELECT DISTINCT sample_id FROM gene_expression_subset
  MINUS
  SELECT sample_id FROM samples
);

-- 3.2 protein_expression_subset の sample_id が samples に存在するか
SELECT 'protein_expression_subset.sample_id NOT IN samples' AS check_name,
       sample_id
FROM (
  SELECT DISTINCT sample_id FROM protein_expression_subset
  MINUS
  SELECT sample_id FROM samples
);

-- 3.3 drug_response_subset の sample_id が samples に存在するか
SELECT 'drug_response_subset.sample_id NOT IN samples' AS check_name,
       sample_id
FROM (
  SELECT DISTINCT sample_id FROM drug_response_subset
  MINUS
  SELECT sample_id FROM samples
);

-- 3.4 drug_response_subset の drug_id が compounds に存在するか
SELECT 'drug_response_subset.drug_id NOT IN compounds' AS check_name,
       drug_id
FROM (
  SELECT DISTINCT drug_id FROM drug_response_subset
  MINUS
  SELECT drug_id FROM compounds
);

-- 3.5 compound_targets の drug_id が compounds に存在するか
SELECT 'compound_targets.drug_id NOT IN compounds' AS check_name,
       drug_id
FROM (
  SELECT DISTINCT drug_id FROM compound_targets
  MINUS
  SELECT drug_id FROM compounds
);

-- ---------------------------------------------------------------------
-- 4. 値域チェック
-- ---------------------------------------------------------------------

-- 4.1 ic50_um が負値になっていないか
SELECT 'ic50_um negative' AS check_name, *
FROM drug_response_subset
WHERE ic50_um < 0;

-- 4.2 tpm が負値になっていないか
SELECT 'tpm negative' AS check_name, *
FROM gene_expression_subset
WHERE tpm < 0;

-- 4.3 protein_abundance が負値になっていないか
SELECT 'protein_abundance negative' AS check_name, *
FROM protein_expression_subset
WHERE protein_abundance < 0;

-- 4.4 auc が 0〜1 の範囲外になっていないか
SELECT 'auc out of [0,1]' AS check_name, *
FROM drug_response_subset
WHERE auc < 0 OR auc > 1;

-- ---------------------------------------------------------------------
-- 5. 重複チェック
-- ---------------------------------------------------------------------

-- 5.1 samples の sample_id 重複
SELECT 'samples duplicate sample_id' AS check_name,
       sample_id, COUNT(*) AS cnt
FROM samples
GROUP BY sample_id
HAVING COUNT(*) > 1;

-- 5.2 gene_expression_subset の (sample_id, gene_symbol) 重複
SELECT 'gene_expression_subset duplicate (sample_id, gene_symbol)' AS check_name,
       sample_id, gene_symbol, COUNT(*) AS cnt
FROM gene_expression_subset
GROUP BY sample_id, gene_symbol
HAVING COUNT(*) > 1;

-- 5.3 protein_expression_subset の (sample_id, protein_symbol) 重複
SELECT 'protein_expression_subset duplicate (sample_id, protein_symbol)' AS check_name,
       sample_id, protein_symbol, COUNT(*) AS cnt
FROM protein_expression_subset
GROUP BY sample_id, protein_symbol
HAVING COUNT(*) > 1;

-- 5.4 drug_response_subset の (sample_id, drug_id) 重複
SELECT 'drug_response_subset duplicate (sample_id, drug_id)' AS check_name,
       sample_id, drug_id, COUNT(*) AS cnt
FROM drug_response_subset
GROUP BY sample_id, drug_id
HAVING COUNT(*) > 1;

-- 5.5 compounds の drug_id 重複
SELECT 'compounds duplicate drug_id' AS check_name,
       drug_id, COUNT(*) AS cnt
FROM compounds
GROUP BY drug_id
HAVING COUNT(*) > 1;
