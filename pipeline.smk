#- Templated section: start ------------------------------------------------------------------------
import os
from bifrostlib import datahandling


os.umask(0o2)
bifrost_sampleComponentObj = datahandling.SampleComponentObj(config["sample_id"], config["component_id"], path=os.getcwd())
sample_name, component_name, dockerfile, options, bifrost_resources = bifrost_sampleComponentObj.load()
provided_species = bifrost_sampleComponentObj.get_sample_properties_by_category("sample_info")['provided_species']

pointfinder_db = {'Salmonella enterica': 'salmonella', 'Campylobacter jejuni': 'campylobacter', "E.coli": "escherichia_coli"}

onerror:
    bifrost_sampleComponentObj.failure()


rule all:
    input:
        # file is defined by datadump function
        component_name + "/datadump_complete"


rule setup:
    output:
        init_file = touch(
            temp(component_name + "/initialized")),
    params:
        folder = component_name


rule_name = "check_requirements"
rule check_requirements:
    message:
        "Running step:" + rule_name
    log:
        out_file = component_name + "/log/" + rule_name + ".out.log",
        err_file = component_name + "/log/" + rule_name + ".err.log",
    benchmark:
        component_name + "/benchmarks/" + rule_name + ".benchmark"
    input:
        folder = rules.setup.output.init_file,
    output:
        check_file = component_name + "/requirements_met",
    params:
        bifrost_sampleComponentObj
    run:
        bifrost_sampleComponentObj.check_requirements()
#- Templated section: end --------------------------------------------------------------------------

#* Dynamic section: start **************************************************************************
rule_name = "cge_pointfinder"
rule cge_pointfinder:
    # Static
    message:
        "Running step:" + rule_name
    log:
        out_file = rules.setup.params.folder + "/log/" + rule_name + ".out.log",
        err_file = rules.setup.params.folder + "/log/" + rule_name + ".err.log",
    benchmark:
        rules.setup.params.folder + "/benchmarks/" + rule_name + ".benchmark"
    # Dynamic
    input:
        contigs = "qcquickie/contigs.fasta"
    output:
        #complete = rules.setup.params.folder + "/data_pointfinder.json",
        outfile = touch(rules.setup.params.folder + "/pointfinder_completed")
    params:
        outfolder = rules.setup.params.folder,
        sampleComponentObj = bifrost_sampleComponentObj,
        organism = pointfinder_db.get(provided_species,"ERROR")
    script:
        os.path.join(os.path.dirname(workflow.snakefile), "scripts/rule__cge_pointfinder.py")
#* Dynamic section: end ****************************************************************************

rule_name = "datadump_pointfinder"
rule datadump_pointfinder:
    # Static
    message:
        "Running step:" + rule_name
    log:
        out_file = rules.setup.params.folder + "/log/" + rule_name + ".out.log",
        err_file = rules.setup.params.folder + "/log/" + rule_name + ".err.log",
    benchmark:
        rules.setup.params.folder + "/benchmarks/" + rule_name + ".benchmark"
    # Dynamic
    input:
        rules.cge_pointfinder.output.outfile
    output:
        summary = touch(rules.all.input)
    params:
        sampleComponentObj = bifrost_sampleComponentObj
    script:
        os.path.join(os.path.dirname(workflow.snakefile), "datadump.py")
