# snowflake-multiomics-handson

Snowflakeでマルチオミクス解析を体験するためのハンズオン教材です。
遺伝子発現・タンパク質発現・薬剤応答・化合物構造情報を、Snowflake上でSQLによって統合し、候補薬剤をRDKit / py3Dmolで3D可視化するまでの一連の流れを体験できます。

Zenn記事「Snowflakeでマルチオミクス解析を体験してみる」のコンパニオン教材です。

## 目的

- 公共ライフサイエンスデータ（ChEMBL / DepMap / CCLE）を題材に
- Snowflakeで複数研究データを統合し
- SQLで品質確認・候補薬剤抽出を行い
- 候補化合物の構造をRDKit / py3Dmolで可視化する

までを、Snowflake Trial Accountとブラウザのみで再現できる構成にしています。

実データそのものではなく、ハンズオン用に簡略化したサブセットです。詳細は `LICENSE_AND_SOURCES.md` を参照してください。

## ファイル構成

```text
snowflake-multiomics-handson/
  README.md
  LICENSE_AND_SOURCES.md
  article.md                          # Zenn記事の本文（参考）

  data/
    samples.csv                       # 細胞株メタデータ
    gene_expression_subset.csv        # 遺伝子発現（TPM）
    protein_expression_subset.csv     # タンパク質発現
    drug_response_subset.csv          # 薬剤応答（IC50, AUC, ラベル）
    compounds.csv                     # 化合物（SMILES等）
    compound_targets.csv              # 化合物と標的の対応

  sql/
    setup.sql                         # DB/Schema/WH/Table/INSERT/Viewを作成
    setup_notebook.sql                # Notebooks on Container Runtime 用の周辺リソース
    analysis.sql                      # 統合解析クエリ
    quality_checks.sql                # データ品質チェック集
    candidate_compounds.sql           # 候補薬剤抽出クエリ

  notebooks/
    01_molecule_visualization.ipynb   # Snowflake Notebooks (Container Runtime) で RDKit / py3Dmol 構造可視化
```

## 実行手順（メイン導線）

CSVロードはステージ設定などで詰まりやすいので、**メイン導線は `setup.sql` の貼り付け実行**です。

1. [Snowflake Trial Account](https://signup.snowflake.com/) を作成します
2. Snowsightにログインします
3. 左メニューから `Worksheets` を開きます
4. `sql/setup.sql` の内容をコピーしてWorksheetに貼り付け、`Run All` を実行します
5. 最後に出る `setup completed` と各テーブルの件数で完了を確認します
6. 続けて、新しいWorksheetで `sql/analysis.sql` を貼り付けて実行し、解析を進めます
7. 必要に応じて `sql/quality_checks.sql` でデータ品質を確認します
8. `sql/candidate_compounds.sql` で候補薬剤を抽出します

実行後、Snowsight上で以下が作成されます。

- Database: `MULTIOMICS_HANDSON`
- Schema: `MULTIOMICS_HANDSON.PUBLIC`
- Warehouse: `HANDSON_WH` （XSMALL, AUTO_SUSPEND=60秒）
- Tables: `samples`, `gene_expression_subset`, `protein_expression_subset`, `drug_response_subset`, `compounds`, `compound_targets`
- View: `multiomics_drug_response_view`

## CSVロードを試す場合（補助導線）

`data/` 配下に同じデータをCSVで置いています。SnowsightのLoad Data UIや `COPY INTO` を試したい場合に利用できます。ただし、ステージ・ファイルフォーマット等で詰まりやすいため、ハンズオン初回はSQLの貼り付け実行をおすすめします。

## Notebookの実行手順（Snowflake Notebooks on Container Runtime）

NotebookはSnowflake上で動かします。ローカルにJupyter/Python環境を用意する必要はありません。

### A. 周辺リソースを作成（ACCOUNTADMIN で1回だけ）

```sql
-- sql/setup_notebook.sql を Snowsight Worksheet にコピー＆ペーストして Run All
```

これで以下が用意されます。

- Compute Pool: `multiomics_compute_pool`（XSノード1台）
- Role: `DATASCIENTIST`（必要権限付与済み）

最後にご自身のユーザーへ `GRANT ROLE DATASCIENTIST TO USER <YOUR_USER>;` でロールを付与してください。

`pip install` 用の追加EAIは、後述のService設定で `SNOWFLAKE.SNOWPARK.PYPI_SHARED_REPOSITORY` を指定すれば不要です。組織ポリシーでこの共有リポジトリが使えない場合のみ、`sql/setup_notebook.sql` のコメント部分（`pypi_access_integration`）を有効化してください。

### B. Workspaces で Notebook を開く

Snowsightの **Workspaces** を使うと、`.ipynb` と `.sql` を1つのワークスペース配下にまとめて扱えます。Workspaces のNotebookでは、**接続時に Database / Schema / Warehouse は選びません**。代わりに「Service」（Compute Pool + Runtime + Artifact Repository + EAI）を選んで接続し、DB/Schema は Notebook 内で `USE` 文か完全修飾名で指定します。

1. 右上のロールセレクタで `DATASCIENTIST` に切り替える
2. 左メニュー `Workspaces` を開き、対象のワークスペース（例: `My Workspace`）を選ぶ
3. `+ Add new` → `Notebook (.ipynb)` を選択し、`01_molecule_visualization.ipynb` という名前で作成する
   - すでにファイルがある場合は、リポジトリの `notebooks/01_molecule_visualization.ipynb` をアップロードしてもOK
4. 開いた `.ipynb` の上部にある `Connect` から **Create new service** を選び、以下を指定する
   - Runtime: 最新のCPUランタイム（例: `v2.5 | CPU | Python 3.12`）
   - Compute pool: `multiomics_compute_pool`
   - Artifact repositories: `SNOWFLAKE.SNOWPARK.PYPI_SHARED_REPOSITORY`
   - External Access Integrations: なし（共有リポジトリでrdkit/py3Dmolが解決できる前提）
5. ステータスが `Connected` になったら、Notebookの先頭セルで以下を実行して対象DBを選択する
   ```python
   from snowflake.snowpark.context import get_active_session
   session = get_active_session()
   session.sql("USE DATABASE MULTIOMICS_HANDSON").collect()
   session.sql("USE SCHEMA   MULTIOMICS_HANDSON.PUBLIC").collect()
   session.sql("USE WAREHOUSE HANDSON_WH").collect()
   ```
6. あとはセル左上の `+ Python` / `+ SQL` / `+ Markdown` でセルを追加・実行する

### C. Notebookで体験できること

- `!pip install rdkit py3Dmol` でパッケージ追加
- `get_active_session()` でSnowflakeに接続（認証情報を書かない）
- `multiomics_drug_response_view` から Sensitive な候補薬剤を直接取得
- 2D構造の描画
- 3Dコンフォマー生成（ETKDG + MMFF最適化）
- py3Dmolによる3D構造の表示
- Erlotinib / Doxorubicin / Gefitinib / Lapatinib の切り替え

## 注意事項

- 本ハンズオンのデータは、教育・技術デモ用に簡略化されたサブセットです。元の公共データセットそのものではありません。
- 表示する3D構造はSMILESから生成した代表的なコンフォマーであり、実際の結晶構造やタンパク質結合状態を表すものではありません。
- 3D構造を眺めただけで薬効や結合親和性を判断することはできません。
- 本ハンズオンで得られる「候補薬剤」や「遺伝子との関係」は、データを統合する流れを示す仮説生成の例であり、医学的・薬学的な結論ではありません。
- 実際の研究利用では、各データソース（ChEMBL / DepMap / CCLE 等）の元データのライセンス・利用条件を必ず確認してください。

## 後片付け

ハンズオンが終わったら、以下で作成オブジェクトを削除できます。

```sql
-- Notebookとデータ
DROP DATABASE  IF EXISTS MULTIOMICS_HANDSON;
DROP WAREHOUSE IF EXISTS HANDSON_WH;

-- Container Runtime 用リソース（ACCOUNTADMIN）
USE ROLE ACCOUNTADMIN;
ALTER COMPUTE POOL multiomics_compute_pool STOP ALL;
DROP COMPUTE POOL  multiomics_compute_pool;
DROP INTEGRATION   pypi_access_integration;
DROP NETWORK RULE  pypi_network_rule;
DROP ROLE          DATASCIENTIST;
```
