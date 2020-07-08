from bifrostlib import datahandling

def extract_cge_pointfinder_report(sampleComponentObj):
    import re
    summary, results, file_path, key = sampleComponentObj.start_data_extraction()
    key = sampleComponentObj.get_file_location_key("resistance/report.tsv")
    print(key)
    data = []
    
    for mut in results[key]:
        print(mut)
    
    return (summary, results)

def datadump(sampleComponentObj, log):
    #sampleComponentObj.start_data_dump(log=log)
    sampleComponentObj.run_data_dump_on_function(extract_cge_pointfinder_report, log=log)
    #sampleComponentObj.end_data_dump(log=log)

datadump(
    snakemake.params.sampleComponentObj,
    snakemake.log)
