#- Templated section: start ------------------------------------------------------------------------
import os
from bifrostlib import datahandling


os.umask(0o2)
bifrost_sampleComponentObj = datahandling.SampleComponentObj(config["sample_id"], config["component_id"])
sample_name, component_name, dockerfile, options, bifrost_resources = bifrost_sampleComponentObj.load()
bifrost_sampleComponentObj.started()

pointfinder_db_names = {'Salmonella enterica': 'salmonella','Campylobacter jejuni': 'campylobacter','Escherichia coli': 'escherichia_coli'} #with this I provide a specific new value used after in the script to look at the specific organism in the database (resources)


onerror:
    print("Workflow error")
    datahandling.update_sample_component_failure(db_sample.get("name", "ERROR") + "__" + component + ".yaml", component)


rule all:
    input:
        component + "/" + component + "_complete"


rule setup:
    output:
        init_file = touch(temp(component + "/" + component + "_initialized")),
    params:
        folder = component


rule_name = "check_requirements"
rule check_requirements:
    # Static
    message:
        "Running step:" + rule_name
    threads:
        global_threads
    resources:
        memory_in_GB = global_memory_in_GB
    log:
        out_file = rules.setup.params.folder + "/log/" + rule_name + ".out.log",
        err_file = rules.setup.params.folder + "/log/" + rule_name + ".err.log",
    benchmark:
        rules.setup.params.folder + "/benchmarks/" + rule_name + ".benchmark"
    # Dynamic
    input:
        folder = rules.setup.output.init_file,
        requirements_file = component_file_name
    output:
        check_file = rules.setup.params.folder + "/requirements_met"
    params:
        component = component_file_name,
        sample = sample,
        sample_component = sample_component_file_name
    run:
        check_requirements.script__initialization(input.requirements_file, params.component, params.sample, params.sample_component, output, log.out_file, log.err_file)
#- Templated section: end --------------------------------------------------------------------------

#* Dynamic section: start **************************************************************************

rule_name = "pointfinder"
rule pointfinder:
    # Static
    message:
        "Running step:" + rule_name
    threads:
        global_threads
    resources:
        memory_in_GB = global_memory_in_GB
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
        reads = (R1, R2),
        contigs = db_sample['path'] + "/qcquickie/contigs.fasta"
    output:
        outfile = touch(rules.setup.params.folder + "/pointfinder_completed")
        #summary = rules.setup.params.folder + "/summary.tsv",
        #resistance_summary = rules.setup.params.folder + "/resistance_summary.tsv"
    params:
        sample_name = db_sample.get("name","ERROR"),
        provided_species = pointfinder_db_names.get(provided_species,"ERROR"),
        outfolder = rules.setup.params.folder,
        db = os.path.join(os.path.dirname(workflow.snakefile), "resources/pointfinder_db")
#        adapters = os.path.join(os.path.dirname(workflow.snakefile), db_component["adapters_fasta"])
    shell:
        os.path.join(os.path.dirname(workflow.snakefile), "scripts/pointfinder.py") + " --id {params.sample_name} --db {params.db} --i {input.contigs} --o {params.outfolder} --organism {params.provided_species}"


rule_name = "datadump_pointfinder"
rule datadump_pointfinder:
    # Static
    message:
        "Running step:" + rule_name
    threads:
        global_threads
    resources:
        memory_in_GB = global_memory_in_GB
    log:
        out_file = rules.setup.params.folder + "/log/" + rule_name + ".out.log",
        err_file = rules.setup.params.folder + "/log/" + rule_name + ".err.log",
    benchmark:
        rules.setup.params.folder + "/benchmarks/" + rule_name + ".benchmark"
    # Dynamic
    input:
        rules.pointfinder.output.outfile
    output:
        summary = touch(rules.all.input)
    params:
        sample = db_sample.get("name", "ERROR") + "__" + component + ".yaml",
        folder = rules.setup.params.folder,
    script:
        os.path.join(os.path.dirname(workflow.snakefile), "datadump.py")
