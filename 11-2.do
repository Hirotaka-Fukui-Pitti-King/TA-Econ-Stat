clear all
set more off

/***********
データのインポート
************/
import delimited 11-2.csv, clear
list

/**************
データ内容
出典: ｢入門 実践する計量経済学｣ サポートページ
著者：藪友良
出版社：東洋経済新報社

データ元: [Card, David and Alan B. Krueger. 1994. Minimum Wages and Employment: A Case Study of the Fast-Food Industry in New Jersey and Pennsylvania, American Economic Review 84(4): 772-793.](https://www.jstor.org/stable/2118030)

業種：ファストフード店

地域：

- ニュージャージー州（NJ）＝ 最低賃金を引き上げた州
- ペンシルベニア州（PA）＝引き上げなかった州

時点：

- 政策前（最低賃金引き上げ前）
- 政策後（引き上げ後）

変数
- store: 店舗ID
- state: 店舗iがニュージャージー(NJ)州に立地しているなら1をとるダミー変数。
- time: 処置後の11月の調査ならば1をとるダミー変数。 
- fulltime: フルタイム換算の雇用者数
- hours: 営業時間
- register: レジの台数

******************************/

*パネルデータの作成
xtset store time

*交差項の作成
gen timestate = time*state

*各state×timeでfulltime平均値の比較
mean fulltime if (state==1 & time==0)  // NJ, before
mean fulltime if (state==1 & time==1)  // NJ, after
mean fulltime if (state==0 & time==0)  // PA, before
mean fulltime if (state==0 & time==1)  // PA, after

/**************
回帰

Y_{i} = \beta_{0}+\beta_{1} \text{state}+\beta_{2} \text{time}+ \beta_{3}(\text{state} \times \text{time})+\epsilon_{i}

Y_{i}: fulltime. フルタイム換算の雇用者数。
****************/

reg fulltime state time timestate, vce(cluster store)

/*************
`vce(cluster store)`: store(店舗id)をクラスターと考え、クラスター頑健誤差を使用。
**************/

*固定効果推定

reg fulltime time timestate i.store, vce(cluster store)

/*************
店舗ごとの固定効果を入れたうえで、最低賃金引き上げの影響を比較
***************/

*追加コントロールを入れた回帰

reg fulltime state time timestate hours register, vce(cluster store)

reg fulltime time timestate hours register i.store, vce(cluster store)

save 11-2.dta, replace
