# Snowflakeでマルチオミクス解析を体験してみる

遺伝子発現・タンパク質発現・薬剤応答・化合物構造情報をSnowflakeでつなぎ、候補薬剤を3D構造で眺めてみます。

このファイルは、Zennで公開している記事と同じ本文のGitHub配布版です。Zennでの公開URLは記事公開後に追記します。

## はじめに

ライフサイエンス領域、特に創薬R&Dの現場では、近年「マルチオミクス」というキーワードをよく目にするようになりました。ゲノム、トランスクリプトーム（mRNA発現）、プロテオーム（タンパク質発現）、メタボロームなど、生体内で起きていることを複数の層から同時に観察し、疾患のメカニズム解明や創薬ターゲットの探索につなげようというアプローチです。

ただ、実際にマルチオミクス解析を始めようとすると、最初にぶつかるのは「高度な統計手法」や「最新のAIモデル」ではなく、もっと地味な、しかし極めて重要な作業です。

- サンプルIDを揃える
- 遺伝子IDやタンパク質IDの命名規則を統一する
- 薬剤名と化合物IDを紐付ける
- 複数の研究データを横断して結合する
- 欠損や不整合がないか品質を確認する

これらを行わずに統計解析やAIに進むと、結果が出ているように見えても、実際にはデータがズレており、解釈不能な結論を出してしまうことがあります。マルチオミクス解析は、いきなり高度なAIや統計解析から始まるわけではなく、まず**データを正しくつなぐデータエンジニアリング**から始まります。

この記事では、その入口の部分を、Snowflakeを使って体験してみます。

## なぜSnowflakeでマルチオミクスなのか

Snowflakeはクラウドデータプラットフォームとして広く知られていますが、ライフサイエンスR&Dにおいても以下のような利点があります。

- 複数の研究データソース（オミクス、薬剤応答、化合物情報、論文メタデータなど）を一元的に統合できる
- SQLで横断的にJOIN・集計・品質確認ができる
- Snowpark Pythonを使えば、SQL統合後のデータを機械学習や統計解析につなげられる
- Streamlit in Snowflakeを使えば、解析結果をそのままダッシュボード化できる
- データ共有機能（Secure Data Sharing）で、他組織や社内別チームと安全にデータを共有できる

要するに、研究データを「保管庫」ではなく「再利用可能な基盤」として扱えるのが大きなポイントです。

## 今回体験すること

このハンズオンでは、以下の流れを体験します。

1. Snowflake上にマルチオミクス解析用のデータベースとテーブルを作成する
2. 遺伝子発現・タンパク質発現・薬剤応答・化合物構造のデータをロードする（SQLで再現）
3. SQLで複数のデータをJOINして統合ビューを作る
4. EGFRやABCB1といった遺伝子と、ErlotinibやDoxorubicinといった薬剤の関係を見る
5. データ品質を確認する
6. 候補薬剤を抽出する
7. RDKitとpy3Dmolで、抽出された候補化合物の3D構造を可視化する

主題は「複数の生命科学データをつなぐデータエンジニアリング」です。高度な統計解析はあえて行いません。

## データセットの考え方

本記事では、ChEMBLやDepMap/CCLEのような公共ライフサイエンスデータを題材に、Snowflakeでマルチオミクス解析の入口を体験します。実際の公共データセットは大きく、前処理やロードにも時間がかかるため、今回はハンズオン用に小さなサブセットをSQLで再現できる形にしました。データ量は小さいですが、サンプルID、遺伝子、タンパク質、薬剤応答、化合物構造をつなぐ考え方は、実際の大規模オミクス解析や創薬データ基盤と同じです。

> 本ハンズオンのデータは、教育・技術デモ用に簡略化したサブセットです。元データそのものではありません。実データを使う場合は、各データソースのライセンス・利用条件を必ず確認してください。

## ハンズオン環境

以下の環境だけで動作します。**ローカルPython / Jupyter は不要です**。

- Snowflake Trial Account（無料）
- ブラウザ（Snowsight）

Notebook部分は Snowflake Notebooks（Run on Container）を使ってSnowflake上で完結させます。Container Runtime では `pip install` が使えるため、RDKit や py3Dmol などライフサイエンス系パッケージも追加できます。

Snowflakeアカウントを持っていない場合は、https://signup.snowflake.com/ から30日間の無料トライアルを作成してください。

## setup.sqlでデータを作成する

CSVロードは便利ですが、Trial環境で初めて触る人にとってはステージ設定やファイルフォーマットなどの落とし穴も多く、事故りやすいポイントです。そのため本ハンズオンでは、**Snowsightのワークシートに `setup.sql` を貼り付けて実行するだけ**ですべてが揃うようにしました。

1. Snowflake Trial Accountを作成する
2. Snowsightにログインする
3. Worksheetsを開く
4. `sql/setup.sql` の内容を貼り付けて実行する
5. セットアップ完了確認のSELECTが返ってくることを確認する

なお、CSVロードは補助導線として `data/` 配下に `samples.csv` などを置いています。本記事のメイン導線は `setup.sql` です。

## データモデル

今回扱うテーブルは以下の6つです。

| テーブル名 | 内容 |
| --- | --- |
| `samples` | 細胞株・サンプルのメタデータ |
| `gene_expression_subset` | サンプル×遺伝子のmRNA発現量（TPM） |
| `protein_expression_subset` | サンプル×タンパク質の発現量 |
| `drug_response_subset` | サンプル×薬剤の感受性（IC50, AUC, ラベル） |
| `compounds` | 化合物情報（SMILES, ChEMBL ID, PubChem CIDなど） |
| `compound_targets` | 化合物と標的タンパク質の対応 |

## 統合View

`setup.sql` の最後に統合Viewを作成しています。

```sql
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
```

## EGFR発現とEGFR阻害薬の感受性を見る

```sql
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
```

## ABCB1と薬剤耐性

```sql
SELECT
  v.cell_line_name,
  v.cancer_type,
  v.gene_symbol,
  v.tpm,
  v.drug_name,
  v.ic50_um,
  v.response_label
FROM multiomics_drug_response_view v
WHERE v.gene_symbol = 'ABCB1'
  AND v.drug_name = 'Doxorubicin'
ORDER BY v.tpm DESC;
```

## 候補薬剤を抽出して構造情報を付与する

```sql
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
```

## Snowflake Notebooks（Container Runtime）で 3D 可視化

`sql/setup_notebook.sql` を ACCOUNTADMIN で実行して、コンピュートプール (`multiomics_compute_pool`) と ロール (`DATASCIENTIST`) を作成しておきます。

Snowsightの **Workspaces** から `.ipynb` を作成（または `notebooks/01_molecule_visualization.ipynb` をアップロード）し、上部の `Connect` → `Create new service` でServiceを作ります。

- Runtime: 最新のCPUランタイム（例: `v2.5 | CPU | Python 3.12`）
- Compute pool: `multiomics_compute_pool`
- Artifact repositories: `SNOWFLAKE.SNOWPARK.PYPI_SHARED_REPOSITORY`
- External Access Integrations: なし（共有リポジトリで rdkit / py3Dmol が解決できる前提）

Workspaces では Connect 時に DB / Schema / Warehouse は選びません。Notebookの先頭セルで `USE` 文を使って切り替えます。

```python
from snowflake.snowpark.context import get_active_session
session = get_active_session()
session.sql("USE DATABASE MULTIOMICS_HANDSON").collect()
session.sql("USE SCHEMA   MULTIOMICS_HANDSON.PUBLIC").collect()
session.sql("USE WAREHOUSE HANDSON_WH").collect()
```

Notebook内で：

```python
!pip install --quiet rdkit py3Dmol
```

```python
from rdkit import Chem
from rdkit.Chem import Draw, AllChem
import py3Dmol
from snowflake.snowpark.context import get_active_session

session = get_active_session()

candidates_df = session.sql("""
    SELECT v.drug_name, c.canonical_smiles, v.ic50_um
    FROM multiomics_drug_response_view v
    JOIN compounds c ON v.drug_id = c.drug_id
    WHERE v.response_label = 'Sensitive'
    ORDER BY v.ic50_um ASC
""").to_pandas()

row    = candidates_df.iloc[0]
smiles = row["CANONICAL_SMILES"]
name   = row["DRUG_NAME"]

mol = Chem.MolFromSmiles(smiles)
Draw.MolToImage(mol, size=(500, 400), legend=name)
```

```python
mol3d = Chem.AddHs(mol)

params = AllChem.ETKDGv3()
params.randomSeed = 42

AllChem.EmbedMolecule(mol3d, params)
AllChem.MMFFOptimizeMolecule(mol3d)

mol_block = Chem.MolToMolBlock(mol3d)

viewer = py3Dmol.view(width=600, height=450)
viewer.addModel(mol_block, "mol")
viewer.setStyle({"stick": {}})
viewer.zoomTo()
viewer.show()
```

データを一度もSnowflakeの外に出さずに、SMILES取得から3D可視化までをSnowflake上で完結できます。

> ここで表示している3D構造は、SMILESから生成した代表的なコンフォマーです。実際の結晶構造やタンパク質結合状態を表すものではありません。3D構造を眺めただけで薬効や結合親和性を判断することはできません。

## 発展

- Snowpark Python: SQL統合済みデータを相関解析や機械学習に
- Streamlit in Snowflake: 候補薬剤や遺伝子・薬剤マップのダッシュボード化
- Cortex: 論文要約や遺伝子・薬剤アノテーション支援
- Iceberg Tables: 大規模オミクスデータレイクや他システムとの相互運用

## まとめ

マルチオミクス解析の入口は、派手な統計やAIではなく、データを正しくつなぐエンジニアリングです。Snowflakeはそこに非常に向いたプラットフォームで、SQL一本で複数の研究データを統合し、Snowpark / Streamlit / Cortexへ自然に拡張できます。

> 本記事のハンズオンは、Snowflakeによるライフサイエンスデータ統合の流れを体験するためのものです。ここで得られる候補薬剤や遺伝子との関係は、仮説生成の例であり、医学的・薬学的な結論ではありません。実際の創薬研究では、統計解析、実験条件の確認、再現性検証、標的妥当性評価、毒性評価、薬物動態、臨床的文脈などを含めた慎重な評価が必要です。
