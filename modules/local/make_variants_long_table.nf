process MAKE_VARIANTS_LONG_TABLE {

    conda "conda-forge::python=3.13.2 conda-forge::matplotlib=3.10.1 conda-forge::pandas=2.2.3 conda-forge::r-sys=3.4.3 conda-forge::regex=2024.11.6 conda-forge::scipy=1.15.2 conda-forge::xlsxwriter=3.2.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/46/469ebfc4e949922a7bc3088453bb9ff54d03736a0e57a34f0d828fee7ef2b764/data' :
        'community.wave.seqera.io/library/matplotlib_pandas_python_r-sys_pruned:a66eb32f9b689889' }"

    input:
    path ('bcftools_query/*')
    path ('snpsift/*')
    path ('pangolin/*')
    val  outname

    output:
    path "*.csv"       , emit: csv
    path "*.xlsx"      , optional: true, emit: excel
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:  // This script is bundled with the pipeline, in nf-core/viralrecon/bin/
    def args = task.ext.args ?: ''
    def is_excel = args.tokenize().contains('--excel')? 'true' : ''
    """
    make_variants_long_table.py \\
        --bcftools_query_dir ./bcftools_query \\
        --snpsift_dir ./snpsift \\
        --pangolin_dir ./pangolin \\
        $args

    if [[ $outname != "merged" ]]; then
        mv variants_long_table.csv ${outname}.variants.csv
        if [[ -n "$is_excel" ]]; then
            mv variants_long_table.xlsx ${outname}.variants.xlsx
        fi
    fi
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
