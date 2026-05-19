-- =====================================================================
-- setup_notebook.sql
--
-- Snowflake Notebooks on Container Runtime で RDKit / py3Dmol を使うための
-- 周辺リソース（コンピュートプール、ロール、ネットワークルール、EAI）を作成します。
--
-- これらは ACCOUNTADMIN 権限が必要なため、setup.sql とは分けています。
-- 既存環境にすでに同等のリソースがある場合は、必要な部分だけ実行してください。
-- =====================================================================

USE ROLE ACCOUNTADMIN;

-- ---------------------------------------------------------------------
-- 1. Compute Pool（Notebook on Container Runtime 用）
-- ---------------------------------------------------------------------
CREATE COMPUTE POOL IF NOT EXISTS multiomics_compute_pool
  MIN_NODES = 1
  MAX_NODES = 1
  INSTANCE_FAMILY = CPU_X64_XS
  AUTO_SUSPEND_SECS = 300;

-- ---------------------------------------------------------------------
-- 2. ロール（Container Runtime Notebookの作成・実行用）
--    ACCOUNTADMIN/ORGADMIN/SECURITYADMIN ではContainer Runtime Notebookを
--    所有・実行できないため、専用ロールを用意します。
-- ---------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS DATASCIENTIST;

GRANT USAGE  ON DATABASE MULTIOMICS_HANDSON              TO ROLE DATASCIENTIST;
GRANT USAGE  ON SCHEMA   MULTIOMICS_HANDSON.PUBLIC       TO ROLE DATASCIENTIST;
GRANT SELECT ON ALL TABLES   IN SCHEMA MULTIOMICS_HANDSON.PUBLIC TO ROLE DATASCIENTIST;
GRANT SELECT ON ALL VIEWS    IN SCHEMA MULTIOMICS_HANDSON.PUBLIC TO ROLE DATASCIENTIST;
GRANT SELECT ON FUTURE TABLES IN SCHEMA MULTIOMICS_HANDSON.PUBLIC TO ROLE DATASCIENTIST;
GRANT SELECT ON FUTURE VIEWS  IN SCHEMA MULTIOMICS_HANDSON.PUBLIC TO ROLE DATASCIENTIST;

GRANT CREATE NOTEBOOK ON SCHEMA MULTIOMICS_HANDSON.PUBLIC TO ROLE DATASCIENTIST;
GRANT CREATE SERVICE  ON SCHEMA MULTIOMICS_HANDSON.PUBLIC TO ROLE DATASCIENTIST;

GRANT USAGE ON WAREHOUSE   HANDSON_WH               TO ROLE DATASCIENTIST;
GRANT USAGE ON COMPUTE POOL multiomics_compute_pool TO ROLE DATASCIENTIST;

-- ご自身のユーザーにDATASCIENTISTロールを付与
-- 例: GRANT ROLE DATASCIENTIST TO USER <YOUR_USER>;

-- ---------------------------------------------------------------------
-- 3. （任意）PyPI 用 External Access Integration
--    Workspaces の Notebook では、Service に
--      Artifact repository: SNOWFLAKE.SNOWPARK.PYPI_SHARED_REPOSITORY
--    を指定すれば pip install が動くため、通常このEAIは不要です。
--    組織ポリシー等で共有リポジトリが使えない場合のみ、以下を有効化して
--    Service側で External Access に紐づけてください。
-- ---------------------------------------------------------------------
-- CREATE OR REPLACE NETWORK RULE pypi_network_rule
--   MODE = EGRESS
--   TYPE = HOST_PORT
--   VALUE_LIST = ('pypi.org', 'pypi.python.org', 'pythonhosted.org', 'files.pythonhosted.org');
--
-- CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION pypi_access_integration
--   ALLOWED_NETWORK_RULES = (pypi_network_rule)
--   ENABLED = TRUE;
--
-- GRANT USAGE ON INTEGRATION pypi_access_integration TO ROLE DATASCIENTIST;

-- ---------------------------------------------------------------------
-- 4. 確認
-- ---------------------------------------------------------------------
SELECT 'notebook prerequisites ready' AS status;

SHOW COMPUTE POOLS LIKE 'multiomics_compute_pool';
SHOW ROLES         LIKE 'DATASCIENTIST';
-- 任意EAIを作成した場合のみ
-- SHOW INTEGRATIONS LIKE 'pypi_access_integration';

-- ---------------------------------------------------------------------
-- 5. 後片付け（ハンズオン終了後）
-- ---------------------------------------------------------------------
-- ALTER COMPUTE POOL multiomics_compute_pool STOP ALL;
-- DROP COMPUTE POOL  multiomics_compute_pool;
-- DROP ROLE          DATASCIENTIST;
-- 任意EAIを作成していた場合
-- DROP INTEGRATION   pypi_access_integration;
-- DROP NETWORK RULE  pypi_network_rule;
