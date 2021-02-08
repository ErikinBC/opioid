#!/bin/bash

# ORDER OF SCRIPTS

echo "(1) Running  process_PHO_coroner.py"
python process_PHO_coroner.py
# outputs: df_phu.csv, df_deaths.csv, di_PHU.csv

echo "(2) Running data_agg.R"
Rscript data_agg.R
# outputs: ~/figures/*.png

echo "(3) Running process_geo.R"
Rscript process_geo.R
# outputs: 




echo "--------- END OF SCRIPT ----------#
