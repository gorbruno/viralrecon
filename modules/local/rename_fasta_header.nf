process RENAME_FASTA_HEADER {
    tag "$meta.id"

    conda "conda-forge::sed=4.8 conda-forge::ripgrep=14.1.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/78/78ed56cf5fba107372a290d51fb780185b29cd6fab3bb8d3544149a821759e90/data' :
        'community.wave.seqera.io/library/ripgrep:14.1.1--aab625f34f38ca76' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.fa"), emit: fasta
    env 'outname'                , emit: outname
    path "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    outname=\$(rename_fasta_header.sh $args --dry)
    
    if [[ -n \$outname ]]; then
        outname_file="\${outname}."
    fi
    rename_fasta_header.sh --fasta $fasta --name ${meta.id} --out \${outname_file}${prefix}.fa $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sed: \$(echo \$(sed --version 2>&1) | sed 's/^.*GNU sed) //; s/ .*\$//')
        ripgrep: \$(rg --version |& sed '1!d ; s/ripgrep //')
    END_VERSIONS
    """
}
