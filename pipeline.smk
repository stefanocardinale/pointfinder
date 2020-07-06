#- Templated section: start ------------------------------------------------------------------------
import os
from bifrostlib import datahandling


os.umask(0o2)
bifrost_sampleComponentObj = datahandling.SampleComponentObj(config["sample_id"], config["component_id"])
sample_name, component_name, dockerfile, options, bifrost_resources = bifrost_sampleComponentObj.load()
bifrost_sampleComponentObj.started()


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

rule_name = "pointfinder"
rule pointfinder:
    # Static
    message:
        "Running step:" + rule_name
    shadow:
        "shallow"
    log:
        out_file = rules.setup.params.folder + "/log/" + rule_name + ".out.log",
        err_file = rules.setup.params.folder + "/log/" + rule_name + ".err.log",
    benchmark:
        rules.setup.params.folder + "/benchmarks/" + rule_name + ".benchmark"
    # Dynamic
    input:
        folder = rules.check_requirements.output.check_file,
        #reads = bifrost_sampleComponentObj.get_reads()
        contigs = "qcquickie/contigs.fasta"
    output:
        outfile = touch(rules.setup.params.folder + "/pointfinder_completed")
        #summary = rules.setup.params.folder + "/summary.tsv",
        #resistance_summary = rules.setup.params.folder + "/resistance_summary.tsv"
    params:
        sample_name = sample_name,
        outfolder = rules.setup.params.folder,
        db = os.path.join(os.path.dirname(workflow.snakefile), "resources/pointfinder_db")
#        adapters = os.path.join(os.path.dirname(workflow.snakefile), db_component["adapters_fasta"])
    shell:
        os.path.join(os.path.dirname(workflow.snakefile), "scripts/pointfinder.py") + " --id {params.sample_name} --db {params.db} --i {input.contigs} --o {params.outfolder}"


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
        rules.pointfinder.output.outfile
    output:
        complete = rules.all.input
    params:
        sampleComponentObj = bifrost_sampleComponentObj
    script:
        os.path.join(os.path.dirname(workflow.snakefile), "datadump.py")
