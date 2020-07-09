from bifrostlib import datahandling

def extract_cge_pointfinder_report(sampleComponentObj):
    import pandas
    summary, results, file_path, key = sampleComponentObj.start_data_extraction("contigs_blastn_results.tsv")

    df = pandas.read_csv(file_path, sep="\t")
    if df.shape[0] > 0:
        # These are all the columns which will be included in the final dataframe except for the collapsed column
        grouped_df = df.groupby(["Mutation","Resistance","Nucleotide change","Amino acid change"])
        # Turn the columns which are not part of the final dataframe into lists, some will have 1 entry some will have multiple
        flattened_df = grouped_df.agg(list)
        # Reset the indexing for formatting purposes otherwise you layer them
        flattened_df = flattened_df.reset_index()
        flattened_df = flattened_df.drop(columns=["PMID"])

        flattened_df = flattened_df.set_index("Mutation")

        results[key] = flattened_df.to_dict(orient="index")
    
    return (summary, results)


def datadump(sampleComponentObj, log):
    sampleComponentObj.start_data_dump(log=log)
    sampleComponentObj.run_data_dump_on_function(extract_cge_pointfinder_report, log=log)
    sampleComponentObj.end_data_dump(log=log)

datadump(
    snakemake.params.sampleComponentObj,
    snakemake.log)
