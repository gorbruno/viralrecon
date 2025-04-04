process IVAR_TRIM_STATS {
    tag "$meta.id"
    label 'process_medium'

    conda "conda-forge::csvtk=0.33.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/98/9882f3dee1cbf7223b14cc7c11284e6d1b21d98e2f19cd23cb41e2fbfb486c70/data' :
        'community.wave.seqera.io/library/csvtk:0.33.0--eb614829ef8176d5' }"

    input:
    tuple val(meta), path(log_file)
    path bed

    output:
    tuple val(meta), path("*.primer_stats.tsv")  , emit: stats
    tuple val(meta), path("*.primer_summary.tsv"), emit: summary
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bed_length=\$(wc -l < $bed)
    bed_width=\$(head -1 $bed | wc -w)

    cols=("reference" "start" "end" "name" "score" "strand" $args)
    selected_cols=\$(printf "%s," "\${cols[@]:0:bed_width}" | sed 's/,\$//')

    cat $log_file | grep "Primer Name" -A \$bed_length | tail -n +2 | csvtk add-header -t -n "name,count" > ${prefix}.ivar_table.tsv
    cat $bed | csvtk add-header -t -n \$selected_cols > ${prefix}.bed.tsv

    csvtk join -t -f name ${prefix}.ivar_table.tsv ${prefix}.bed.tsv > ${prefix}.primer_stats.tsv
    csvtk summary -t -g "strand" -f count:sum ${prefix}.primer_stats.tsv | csvtk transpose -t | cut -f2,3 > ${prefix}.primer_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        csvtk: \$(csvtk version | sed 's/^csvtk v//')
    END_VERSIONS
    """
}
