#!/usr/bin/sh

export SPARK_SUBMIT_OPTIONS="--packages com.databricks:spark-csv_2.10:1.4.0"

pip install sklearn
pip install matplotlib
pip install seaborn

