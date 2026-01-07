clear all
set more off

* データの読み込み
import delimited 11-1.csv, clear 

list

* パネルデータの設定
xtset id year

* 交差項ダミー変数の作成
gen dtd2=dt*d2

* 固定効果モデルの推定
xtreg y dt d2 dtd2,fe

*データの保存
save 11-1.dta, replace

