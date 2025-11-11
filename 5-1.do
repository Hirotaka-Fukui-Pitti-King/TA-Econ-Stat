*******************************************************
* panel_build_all.do
*  5-0.xlsx / 5-1.csv / 5-2.csv / 5-3.csv / 5-4.csv / 5-5.csv
*  を用い、講義ノートの手順を Stata 内だけで完結
*   - 転置(必要時) → wide→long → 結合 → xtset → 推定
*******************************************************

clear all
set more off

* -----------------------------------------------------
* 小道具：年列 T を y1,y2,... の末尾から推定
program define guess_T, rclass
    syntax, prefix(name)
    qui ds `prefix'*
    local maxT = 0
    foreach v of varlist `r(varlist)' {
        local stem = subinstr("`v'","`prefix'","",.)
        capture confirm number `stem'
        if (_rc==0) {
            local n = real("`stem'")
            if (`n' > `maxT') local maxT = `n'
        }
    }
    return scalar T = `maxT'
end

* 縦ベクトル（1～2列×長い行数）っぽければ自動転置
program define ensure_wide, rclass
    qui count
    local N = r(N)
    qui ds
    local K : word count `r(varlist)'
    if (`K'<=3 & `N'>`K') {
        di as txt ">> Tall vector-like input detected; applying xpose..."
        xpose, clear varname
        * 変数名を x1, x2, ... に整える
        local i = 1
        qui ds
        foreach v of varlist `r(varlist)' {
            rename `v' x`i'
            local ++i
        }
    }
end

* -----------------------------------------------------

*******************************************************
* A. 講義ノート 基本形１/２： y と rd をパネル化 → 5-3.dta まで
*    （import → 転置(必要時) → reshape long → merge → xtset）
*    reshape: Step⑦ / xtset: Step⑨ / merge: 基本形２ Step⑤
*    【講義ノート準拠】:contentReference[oaicite:2]{index=2}
*******************************************************

* --- y系列：5-1.csv ---
import delimited using "$DATADIR/5-1.csv", varnames(1) case(lower) clear
quietly ensure_wide

* id が無ければ作成
capture confirm var id
if _rc {
    gen id = _n
    order id
}

* y1 y2 ... を検出 → long 化
capture noisily ds y*
if _rc {
    di as err "y* 形式の列が見当たりません（例: y1,y2,...）。5-1.csv を確認してください。"
    exit 198
}
quietly guess_T, prefix(y)
local T = r(T)
if (`T'==0) {
    di as err "年Tを列名から推定できません（y1,y2,... を想定）。"
    exit 198
}

tempfile ywide
save `ywide', replace
reshape long y, i(id) j(year)     // 【reshape：Step⑦】:contentReference[oaicite:3]{index=3}
tempfile ylong
save `ylong', replace
xtset id year                      // 【xtset：Step⑨】:contentReference[oaicite:4]{index=4}
save "$OUTDIR/5-1.dta", replace

* --- rd系列：5-2.csv ---
import delimited using "$DATADIR/5-2.csv", varnames(1) case(lower) clear
quietly ensure_wide

capture confirm var id
if _rc {
    gen id = _n
    order id
}

capture noisily ds rd*
if _rc {
    di as err "rd* 形式の列が見当たりません（例: rd1,rd2,...）。5-2.csv を確認してください。"
    exit 198
}
quietly guess_T, prefix(rd)
local T2 = r(T)
if (`T2'==0) {
    di as err "年Tを列名から推定できません（rd1,rd2,... を想定）。"
    exit 198
}

tempfile rdwide
save `rdwide', replace
reshape long rd, i(id) j(year)    // 【reshape：Step⑦】:contentReference[oaicite:5]{index=5}
tempfile rdlong
save `rdlong', replace
xtset id year
save "$OUTDIR/5-2.dta", replace

* --- y と rd を 1:1 結合 ---
use `ylong', clear
merge 1:1 id year using `rdlong'  // 【merge：基本形２ Step⑤】:contentReference[oaicite:6]{index=6}
drop _merge
order id year y rd
xtset id year                     // 【xtset：Step⑨】:contentReference[oaicite:7]{index=7}
save "$OUTDIR/5-3.dta", replace

*******************************************************
* B. 講義ノート 第Ⅲ部（練習）：iv と y で推定用パネル
*    5-3.csv（設備投資 iv）と 5-4.csv（売上高 y）を統合し FE/RE
*    「doファイル作成→結合→reshape→xtset→推定」の流れを再現
*    :contentReference[oaicite:8]{index=8}
*******************************************************

* --- iv：5-3.csv （wide→long）---
import delimited using "$DATADIR/5-3.csv", varnames(1) case(lower) clear
quietly ensure_wide

capture confirm var id
if _rc {
    gen id = _n
    order id
}

capture noisily ds iv*
if _rc {
    di as err "iv* 形式の列が見当たりません（例: iv1,iv2,...）。5-3.csv を確認してください。"
    exit 198
}
quietly guess_T, prefix(iv)
local Tiv = r(T)
if (`Tiv'==0) {
    di as err "年Tを列名から推定できません（iv1,iv2,... を想定）。"
    exit 198
}
tempfile ivwide
save `ivwide', replace
reshape long iv, i(id) j(year)
tempfile ivlong
save `ivlong', replace

* --- y：5-4.csv（wide→long）---
import delimited using "$DATADIR/5-4.csv", varnames(1) case(lower) clear
quietly ensure_wide

capture confirm var id
if _rc {
    gen id = _n
    order id
}

capture noisily ds y*
if _rc {
    di as err "y* 形式の列が見当たりません（例: y1,y2,...）。5-4.csv を確認してください。"
    exit 198
}
quietly guess_T, prefix(y)
local Ty = r(T)
if (`Ty'==0) {
    di as err "年Tを列名から推定できません（y1,y2,... を想定）。"
    exit 198
}
tempfile y2wide
save `y2wide', replace
reshape long y, i(id) j(year)
tempfile y2long
save `y2long', replace

* --- iv と y を結合 → パネル宣言 ---
use `ivlong', clear
merge 1:1 id year using `y2long'  // 【merge：基本形２ Step⑤】:contentReference[oaicite:9]{index=9}
drop _merge
order id year iv y
xtset id year                     // 【xtset：Step⑨】:contentReference[oaicite:10]{index=10}
save "$OUTDIR/5-5.dta", replace

* --- 推定（固定効果 / 変量効果、＋Hausman）---
xtreg iv y, fe
estimates store FE

xtreg iv y, re
estimates store RE

capture noisily hausman FE RE, sigmamore

* 任意：結果保存（estout/esttab を入れている場合）
capture which esttab
if !_rc {
    esttab FE RE using "$OUTDIR/panel_iv_y_results.rtf", replace se b(%9.4f) se(%9.4f) star(* 0.10 ** 0.05 *** 0.01) nonotes
    di as res ">> Results saved: $OUTDIR/panel_iv_y_results.rtf"
}

