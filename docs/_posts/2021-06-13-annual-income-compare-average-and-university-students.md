---
layout: single
title:  "大学生がいる世帯と一般的な勤労世帯の年収比較"
classes:
    - dark-theme
---

大学生がいる世帯と一般的な2人以上で構成される世帯との平均年収は大きく異なっている

<iframe width="600" height="350" src="https://datastudio.google.com/embed/reporting/05731a38-9961-446e-a331-9782ef1fa429/page/BGzOC" frameborder="0" style="border:0" allowfullscreen></iframe>

一般的な世帯の年収は550万円ほどであるのに対し、大学生がいる世帯の平均年収は800万円を超えている（正確には860万円。集計データを元にした計算の都合上、グラフ上と実際の値との乖離がある）

大学生がいる世帯の少なくとも60%以上が、一般的な世帯の年収より多い世帯年収である。

### Data Source
- JASSO学生生活調査(2018年度分) https://www.jasso.go.jp/about/statistics/gakusei_chosa/index.html
- 家計調査(2020年度分) https://www.e-stat.go.jp/stat-search/database?page=1&layout=datalist&toukei=00200561&tstat=000000330001&cycle=7&tclass1=000000330001&tclass2=000000330004&tclass3val=0

### Processing
- JASSO学生生活調査
    - 大学生がいる世帯の年収5分位データを計算
    - 「３－１表　家庭の年間収入別学生数の割合（大学昼間部）」を元に計算
    - 性別に依存しないデータを仕様
    - 年収範囲の中央値（200-300万円の年収範囲の場合は、その範囲に含まれる世帯の年収は250万円と考えて計算）
- 家計調査
    - 2人以上の勤労者世帯の年収5分位データを取得
    - 「用途分類（年間収入五分位階級別）」を元に取得
    - 実収入を年収として利用
    - 2018年度のデータを利用