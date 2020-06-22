import os
import sys
import traceback
import shutil
from bifrostlib import datahandling
from bifrostlib import check_requirements

component = "pointfinder"  # Depends on component name, should be same as folder

configfile: "../config.yaml"  # Relative to run directory
global_threads = config["threads"]
global_memory_in_GB = config["memory"]
sample = config["Sample"]

sample_file_name = sample
db_sample = datahandling.load_sample(sample_file_name)
provided_species = db_sample["properties"].get("provided_species","ERROR")
pointfinder_db_names = {'Clostridioides difficile': 'Cdifficile','Salmonella enterica': 'Salmonella'}

component_file_name = "../components/" + component + ".yaml"
if not os.path.isfile(component_file_name):
    shutil.copyfile(os.path.join(os.path.dirname(workflow.snakefile), "config.yaml"), component_file_name) #this creates the component's yaml file by copying the main config.yaml content into it
db_component = datahandling.load_component(component_file_name) #This function will create the component object as yaml and python dict

sample_component_file_name = db_sample["name"] + "__" + component + ".yaml"
db_sample_component = datahandling.load_sample_component(sample_component_file_name) #This will create the sample component object as yaml and python dict

if "reads" in db_sample:
    reads = R1, R2 = db_sample["reads"]["R1"], db_sample["reads"]["R2"]
else:
    reads = R1, R2 = ("/dev/null", "/dev/null")

onsuccess:
    print("Workflow complete")
    datahandling.update_sample_component_success(db_sample.get("name", "ERROR") + "__" + component + ".yaml", component)


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
        outfolder = rules.setup.params.folder + "/results",
        db = os.path.join(os.path.dirname(workflow.snakefile), "resources/pointfinder_db")
#        adapters = os.path.join(os.path.dirname(workflow.snakefile), db_component["adapters_fasta"])
    shell:
        os.path.join(os.path.dirname(workflow.snakefile), "scripts/pointfinder.py") + " --id {params.sample_name} --db {params.db} --i {input.contigs} --o {params.outfolder} --organism {params.provided_species}"


rule_name = "datadump_kma_pointmutations"
rule datadump_kma_pointmutations:
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
        folder = rules.setup.params.folder + "/results",
    script:
        os.path.join(os.path.dirname(workflow.snakefile), "datadump.py")
