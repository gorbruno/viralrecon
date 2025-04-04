process CLEAN_FASTA {
    tag "$meta.id"

    conda "conda-forge::sed=4.8 bioconda::seqkit=2.9.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/da/da5280983342416ade030f9f45384470205bdcf83e1785981ffa5b30fb6ad082/data' :
        'community.wave.seqera.io/library/seqkit_sed:120f7b17ba1f7415' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.cleaned.fa"), emit: fasta
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    seqkit -is replace -p "^n+|n+\$" -r "" $args $fasta > ${prefix}.cleaned.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqkit: \$(echo \$(seqkit version 2>&1) | sed 's/^.*seqkit v//')
    END_VERSIONS
    """
}
