process BUILD_PHYLOGENETIC_TREE_PARSNP {

    tag( "${meta.snp_package}-${meta.recombination}" )
    label "process_high"
    container "quay.io/biocontainers/parsnp@sha256:b46999fb9842f183443dd6226b461c1d8074d4c1391c1f2b1e51cc20cee8f8b2"

    input:
    tuple val(meta), path(masked_alignment)

    output:
    tuple val(meta), path("*.Final.tree"), optional: true, emit: tree
    tuple val(meta), path("*.Tree_Output_File.tsv")      , emit: qc_filecheck
    path(".command.{out,err}")
    path("versions.yml")                                 , emit: versions

    script:
    def tree_file = "${meta.snp_package}-${meta.recombination}.Final.tree"
    def qc_file = "${meta.snp_package}-${meta.recombination}.Tree_Output_File.tsv"
    """
    source bash_functions.sh

    echo "=== Tree Building Debug Info ==="
    echo "Working directory: \$(pwd)"
    echo "Input alignment: ${masked_alignment}"
    echo "Tree method: ${params.tree_method}"
    echo "Expected output: ${tree_file}"
    echo "Min file size: ${params.min_tree_filesize}"
    echo "================================"

    # Check input file
    if [ ! -f "${masked_alignment}" ]; then
        echo "ERROR: Input alignment file ${masked_alignment} not found"
        exit 1
    fi

    if [ ! -s "${masked_alignment}" ]; then
        echo "ERROR: Input alignment file ${masked_alignment} is empty"
        exit 1
    fi

    echo "Input alignment file size: \$(wc -c < ${masked_alignment}) bytes"
    echo "Input alignment preview:"
    head -n 5 "${masked_alignment}"

    if [[ "${params.tree_method}" = "fasttree" ]]; then
      msg "INFO: Building phylogenetic tree using FastTree."

      # Add timeout and better error handling for FastTree
      timeout 2h fasttree \\
        -nt "${masked_alignment}" \\
        > "${tree_file}" || {
        exit_code=\$?
        echo "FastTree failed with exit code: \$exit_code"
        if [ \$exit_code -eq 124 ]; then
            echo "ERROR: FastTree timed out after 2 hours"
        fi
        exit \$exit_code
      }

    elif [[ "${params.tree_method}" = "raxml" ]]; then
      msg "INFO: Building phylogenetic tree using RaxML."

      # Add timeout for RaxML
      timeout 4h raxmlHPC-PTHREADS \\
        -s "${masked_alignment}" \\
        -m GTRGAMMA \\
        -n "${meta.recombination}" \\
        -p 5280 || {
        exit_code=\$?
        echo "RaxML failed with exit code: \$exit_code"
        if [ \$exit_code -eq 124 ]; then
            echo "ERROR: RaxML timed out after 4 hours"
        fi
        exit \$exit_code
      }

      mv "RAxML_bestTree.${meta.recombination}" "${tree_file}"
    else
      echo "ERROR: Unknown tree method: ${params.tree_method}"
      exit 1
    fi

    echo "Tree building completed. Checking output..."
    
    # List all files created
    echo "Files in working directory:"
    ls -la

    # Check if tree file was created
    if [ ! -f "${tree_file}" ]; then
        echo "ERROR: Tree file ${tree_file} was not created"
        exit 1
    fi

    echo "Tree file size: \$(wc -c < ${tree_file}) bytes"
    echo "Tree file preview:"
    head -n 3 "${tree_file}"

    # Enhanced QC check with detailed logging
    echo -e "Sample name\\tQC step\\tOutcome (Pass/Fail)" > "${qc_file}"

    # Get actual file size in bytes
    actual_size=\$(wc -c < "${tree_file}")
    
    # Parse minimum size (handle 'c' suffix for characters/bytes)
    min_size_param="${params.min_tree_filesize}"
    if [[ "\$min_size_param" =~ ^([0-9]+)c\$ ]]; then
        min_size_bytes=\${BASH_REMATCH[1]}
    elif [[ "\$min_size_param" =~ ^([0-9]+)\$ ]]; then
        min_size_bytes=\$min_size_param
    else
        # Default to 50 bytes if parsing fails
        min_size_bytes=50
        echo "Warning: Could not parse min_tree_filesize '\$min_size_param', using default 50 bytes"
    fi
    
    echo "QC Check Details:"
    echo "  File: ${tree_file}"
    echo "  Actual size: \$actual_size bytes"
    echo "  Minimum required: \$min_size_bytes bytes"
    echo "  Size parameter: \$min_size_param"
    echo "  Size check: \$([ \$actual_size -gt \$min_size_bytes ] && echo "PASS" || echo "FAIL")"

    # Use a more reliable size check
    if [ \$actual_size -gt \$min_size_bytes ]; then
        echo -e "${meta.recombination}\\tFinal Tree Output\\tPASS" >> "${qc_file}"
        echo "✅ QC PASS: Tree file meets minimum size requirement (\$actual_size > \$min_size_bytes bytes)"
        echo "✅ Tree file will be published to output directory"
    else
        echo -e "${meta.recombination}\\tFinal Tree Output\\tFAIL" >> "${qc_file}"
        echo "❌ QC FAIL: Tree file too small (\$actual_size <= \$min_size_bytes bytes)"
        echo "❌ Tree file will be removed and not published"
        
        # Only remove if it's actually too small
        rm "${tree_file}"
    fi

    echo "Final files in directory:"
    ls -la *.tree *.tsv 2>/dev/null || echo "No tree or tsv files found"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fasttree: \$(fasttree -expert 2>&1 | head -1 | sed 's/^/    /' || echo "    version unknown")
        raxml: \$(raxmlHPC-PTHREADS -v 2>&1 | head -1 | sed 's/^/    /' || echo "    version unknown")
    END_VERSIONS
    """
}
