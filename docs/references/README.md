# 論文資料の配置

このディレクトリは、boostPM の統計仕様を確認するための文献資料を置く場所です。

## 現在の資料

- 本文: `paper/Awaya_Ma_2024.pdf`
- 書誌情報: `metadata/awaya-2024.md`

## 推奨構成

```text
docs/references/
├── README.md
├── paper/
│   └── <first-author>-<year>-<short-title>.pdf
├── supplementary/
│   └── <first-author>-<year>-supplement.pdf
└── metadata/
    └── <first-author>-<year>.md
```

必要なサブディレクトリは、資料を追加するときに作成します。

## ファイル名

ファイル名には、半角英数字、小文字、ハイフンを使用します。

例：

```text
paper/yamada-2023-boostpm.pdf
supplementary/yamada-2023-supplement.pdf
metadata/yamada-2023.md
```

出版社から取得した元のPDFは編集せず、そのまま保存します。

## メタデータ

`metadata/<first-author>-<year>.md` には、少なくとも次の情報を記録します。

- 論文名
- 著者
- 掲載誌または公開元
- 出版年
- DOIまたは恒久的URL
- PDFの入手元
- 取得日
- 論文、補足資料、公開コードのバージョン関係
- 再配布条件またはライセンス
- SHA-256チェックサム

## 著作権とGit管理

論文PDFをリポジトリへコミットする前に、再配布が許可されているか確認します。

- オープンアクセスなど、再配布可能なPDFはコミット候補になります。
- 購読契約や個人アクセスで取得したPDFは、通常はローカル参照のみとします。
- 再配布条件が不明な場合、PDFはコミットせず、メタデータと入手先URLだけを記録します。

## 仕様化での扱い

資料を参照した記述には、次のラベルを使用します。

- confirmed from the paper
- confirmed from the supplementary material
- confirmed from the original code
- inferred from context
- unresolved
- possible bug
- possible numerical issue

論文と `original/` の実装が一致しない場合、どちらかを黙って採用せず、`docs/statistical-specification.md` に相違点を記録します。
