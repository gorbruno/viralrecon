process MULTIQC {
    label 'process_medium'

    conda "bioconda::multiqc=1.27 conda-forge::pandas=2.2.3 conda-forge::xlsxwriter=3.2.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/ca/ca67c9f6b56ae35ad4051da5951562b080beed68cbb8d6a89fa86b690d0dd8fd/data' :
        'community.wave.seqera.io/library/multiqc_pandas_xlsxwriter:87f9a4ec1eb40c19' }"

    input:
    path  multiqc_files, stageAs: "?/*"
    path(multiqc_config)
    val  outname
    path(extra_multiqc_config)
    path(multiqc_logo)
    path workflow_summary
    path fail_reads_summary
    path fail_mapping_summary
    path 'amplicon_heatmap_mqc.tsv'
    path ('fastqc/*')
    path ('fastp/*')
    path ('kraken2/*')
    path ('bowtie2/*')
    path ('bowtie2/*')
    path ('bowtie2/*')
    path ('ivar_trim/*')
    path ('ivar_trim/*')
    path ('ivar_trim/*')
    path ('picard_markduplicates/*')
    path ('mosdepth/*')
    path ('variants/*')
    path ('variants/*')
    path ('variants/*')
    path ('variants/*')
    path ('variants/*')
    path ('variants/*')
    path ('cutadapt/*')
    path ('assembly_spades/*')
    path ('assembly_unicycler/*')
    path ('assembly_minia/*')
    path ('freyja_demix/*')

    output:
    path "*.html"                 , emit: report
    path "*_data"                 , emit: data
    path "*variants*metrics*csv"  , optional:true, emit: csv_variants
    path "*assembly*metrics*csv"  , optional:true, emit: csv_assembly
    path "*variants*metrics*xlsx" , optional:true, emit: excel_variants
    path "*assembly*metrics*xlsx" , optional:true, emit: excel_assembly
    path "*_plots"                , optional:true, emit: plots
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def config = multiqc_config ? "--config $multiqc_config" : ''
    def extra_config = extra_multiqc_config ? "--config $extra_multiqc_config" : ''
    def logo = multiqc_logo ? /--cl-config 'custom_logo: "${multiqc_logo}"'/ : ''
    def is_excel = args2.tokenize().contains('--excel')? 'true' : ''
    def outname_final = outname != 'merged' ? "${outname}." : ''
    """
    ## Run MultiQC once to parse tool logs
    multiqc -f $args $config $extra_config $logo.

    ## Parse YAML files dumped by MultiQC to obtain metrics
    multiqc_to_custom_csv.py --platform illumina $args2

    ## Manually remove files that we don't want in the report
    if grep -q ">skip_assembly<" workflow_summary_mqc.yaml; then
        rm -f *assembly_metrics_mqc*
        ass=""
    else
        ass=1
    fi

    if grep -q ">skip_variants<" workflow_summary_mqc.yaml; then
        rm -f *variants_metrics_mqc*
        var=""
    else
        var=1
    fi

    rm -f variants/report.tsv
    rm -f variants/nextclade_clade_mqc.tsv
    rm -f multiqc_data/multiqc_nextclade_clade.yaml
    rm -f multiqc_data/multiqc_ivar_trim_primer_statistics.yaml
    rm -f ivar_trim/ivar_trim_primer_statistics_mqc.tsv

    ## Run MultiQC a second time
    multiqc -f $args -e general_stats --ignore nextclade_clade_mqc.tsv $config $extra_config $logo .
    
    # TODO: fck off misha
    mv multiqc_report.html ${outname_final}multiqc.html # fck off misha

    if [[ -n "\$var" ]]; then
        mv *variants_metrics_mqc.csv ${outname_final}.variants.metrics.csv # fck off misha
        if [[ -n "$is_excel" ]]; then mv *variants_metrics_mqc.xlsx ${outname_final}variants.metrics.xlsx; fi # fck off misha
    fi
    
    if [[ -n "\$ass" ]]; then
        mv *assembly_metrics_mqc.csv ${outname_final}assembly.metrics.csv # fck off misha
        if [[ -n "$is_excel" ]]; then mv *assembly_metrics_mqc.xlsx ${outname_final}assembly.metrics.xlsx; fi # fck off misha
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed -e "s/multiqc, version //g" )
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
