clear all
set more off

import delimited 11-1.csv, clear

list

xtset id year

gen dtd2=dt*d2

xtreg y dt d2 dtd2,fe

