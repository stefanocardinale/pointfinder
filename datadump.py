import pkg_resources
from ruamel.yaml import YAML
import os
import re
from bifrostlib import datahandling
import sys

config = datahandling.load_config()

global GLOBAL_BIN_VALUES
GLOBAL_BIN_VALUES = [1, 10, 25]

def extract_tsv(datadump_dict, folder, relative_path):
    #relative_path_key = relative_path.replace(".", "_")
    if os.path.isfile(os.path.join(folder, relative_path)):
        datadump_dict["results"][relative_path] = {}
        try:
            with open(os.path.join(folder, relative_path), "r") as tsv_file:
                values = []
                headers = None
                for line in tsv_file:
                    line = line.strip()
                    if headers is None:
                        headers = line.split('\t')
                    else:
                        row = line.split('\t')
                        values.append(dict(zip(headers, row)))
        except Exception as e:
            sys.stderr.write(relative_path, e)
            sys.stderr.write(datadump_dict)
            datadump_dict["results"][relative_path]["status"] = "datadumper error"
        datadump_dict["results"][relative_path]["values"] = values
        datadump_dict["summary"][relative_path] = values
        
    return datadump_dict


def script__datadump_kma_pointmutations(folder, sample):
    folder = str(folder)
    sample = str(sample)
    data_dict = datahandling.load_sample_component(sample)
    data_dict["summary"] = data_dict.get("summary", {})
    data_dict["results"] = data_dict.get("results", {})
    data_dict = extract_tsv(data_dict, folder, "contigs_blastn_results.tsv")

    datahandling.save_sample_component(data_dict, sample)

    return 0

script__datadump_kma_pointmutations(snakemake.params.folder, snakemake.params.sample)
