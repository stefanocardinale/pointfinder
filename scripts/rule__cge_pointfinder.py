# script for use with snakemake
import sys
import subprocess
import traceback
from bifrostlib import datahandling


def rule__run_cge_pointfinder(input, output, organism, sampleComponentObj, log):
    try:
        this_function_name = sys._getframe().f_code.co_name

        # Code to run
        sampleComponentObj.rule_run_cmd("/bifrost_resources/pointfinder/PointFinder.py -i {} -o {} -s {} -p /srv/data/BIG/stefano_playground/test3/pointfinder_db -m blastn -m_p /opt/conda/pkgs/blast-2.9.0-h20b68b9_1/bin/blastn".format(
            input.contigs, output, organism), log)

        sampleComponentObj.end_rule(this_function_name, log=log)
    except Exception:
        sampleComponentObj.write_log_err(log, str(traceback.format_exc()))


rule__run_cge_pointfinder(
    snakemake.input,
    snakemake.params.outfolder,
    snakemake.params.organism,
    snakemake.params.sampleComponentObj,
    snakemake.log)
