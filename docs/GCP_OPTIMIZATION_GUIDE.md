# GCP Optimization Guide for wf-assembly-snps-gcp

## Overview

This guide provides comprehensive instructions for running the bacterial genomics SNP pipeline on Google Cloud Platform (GCP) with optimal cost efficiency and performance. The optimizations address specific concerns about Gubbins resource usage and provide alternatives for processing hundreds of FASTA files cost-effectively.

## Key Optimizations Implemented

### 1. **Gubbins Resource Optimization**
- **Adaptive parameter selection** based on dataset size
- **Progressive retry strategy** with increasing resources
- **Alternative ClonalFrameML option** (5-10x faster, much cheaper)
- **Resource monitoring** and automatic scaling

### 2. **Cost Optimization**
- **Preemptible instances** (70% cost reduction)
- **Right-sized machine types** for each process
- **Intelligent resource allocation** based on input size
- **Cost estimation and monitoring** tools

### 3. **Enhanced Debugging**
- **Comprehensive logging** with system resource monitoring
- **Real-time performance tracking**
- **Detailed error reporting** with troubleshooting guides
- **Cost tracking** and budget alerts

## Quick Start

### Prerequisites
1. Google Cloud Project with billing enabled
2. Google Cloud SDK installed and configured
3. Nextflow installed (≥22.04.3)
4. Docker enabled

### Basic Usage

```bash
# Set your GCP project
export GOOGLE_CLOUD_PROJECT="your-project-id"

# Run with optimized settings
nextflow run bacterial-genomics/wf-assembly-snps \
    -profile gcp_minimal \
    --input gs://your-bucket/input-fastas/ \
    --outdir gs://your-bucket/results/ \
    --recombination clonalframeml \
    --use_preemptible true \
    --estimated_genome_count 200 \
    --max_estimated_cost 50.0
```

## Configuration Profiles

### `gcp_minimal` Profile
Optimized for cost-effective processing with minimal VMs:
- Uses preemptible instances by default
- Right-sized machine types for each process
- Enhanced error handling and retry strategies
- Comprehensive logging and monitoring

## Cost Optimization Strategies

### 1. **Choose the Right Recombination Method**

| Method | Speed | Cost | Accuracy | Best For |
|--------|-------|------|----------|----------|
| **ClonalFrameML** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Most use cases |
| Gubbins | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | High-precision studies |
| None | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | N/A | Exploratory analysis |

**Recommendation**: Use ClonalFrameML for most bacterial genomics applications.

```bash
# Use ClonalFrameML (recommended)
--recombination clonalframeml

# Or optimize Gubbins if needed
--recombination gubbins \
--gubbins_iterations 3 \
--gubbins_model_fitter fasttree
```

### 2. **Dataset Size Optimization**

#### Small Datasets (<100 genomes)
```bash
nextflow run bacterial-genomics/wf-assembly-snps \
    -profile gcp_minimal \
    --input gs://your-bucket/input/ \
    --outdir gs://your-bucket/results/ \
    --recombination clonalframeml \
    --use_preemptible true \
    --estimated_genome_count 50 \
    --max_estimated_cost 25.0
```
**Expected cost**: $5-15

#### Medium Datasets (100-300 genomes)
```bash
nextflow run bacterial-genomics/wf-assembly-snps \
    -profile gcp_minimal \
    --input gs://your-bucket/input/ \
    --outdir gs://your-bucket/results/ \
    --recombination clonalframeml \
    --use_preemptible true \
    --gubbins_cpus 4 \
    --parsnp_cpus 4 \
    --estimated_genome_count 200 \
    --max_estimated_cost 75.0
```
**Expected cost**: $15-50

#### Large Datasets (300+ genomes)
```bash
nextflow run bacterial-genomics/wf-assembly-snps \
    -profile gcp_minimal \
    --input gs://your-bucket/input/ \
    --outdir gs://your-bucket/results/ \
    --recombination clonalframeml \
    --use_preemptible true \
    --gubbins_cpus 8 \
    --parsnp_cpus 8 \
    --skip_excel_outputs true \
    --cleanup_work_dir true \
    --estimated_genome_count 500 \
    --max_estimated_cost 200.0
```
**Expected cost**: $50-150

### 3. **Preemptible Instance Strategy**
Preemptible instances provide 70% cost savings but can be interrupted:

```bash
# Enable preemptible instances (recommended)
--use_preemptible true

# For critical production runs, disable if needed
--use_preemptible false
```

## Advanced Configuration

### Resource Optimization Parameters

```bash
# Gubbins optimization
--gubbins_cpus 4                    # CPU cores for Gubbins
--gubbins_memory "16 GB"            # Memory allocation
--gubbins_time "6 h"                # Time limit
--gubbins_iterations 3              # Reduce iterations for speed
--gubbins_model_fitter fasttree     # Faster tree builder

# ParSNP optimization
--parsnp_cpus 4                     # CPU cores for ParSNP
--parsnp_memory "8 GB"              # Memory allocation

# Alternative recombination
--use_clonalframeml_instead true    # Use ClonalFrameML instead of Gubbins
```

### Monitoring and Debugging

```bash
# Enhanced monitoring
--monitor_resource_usage true       # Track resource usage
--log_cost_estimates true          # Monitor costs
--verbose_logging true             # Detailed logs
--debug_mode false                 # Enable for troubleshooting

# Cost controls
--max_estimated_cost 100.0         # Budget limit (USD)
--estimated_genome_count 200       # Help with cost estimation
```

### Data Management

```bash
# Storage optimization
--cleanup_work_dir true            # Clean intermediate files
--compress_outputs false           # Compress outputs (slower)
--stage_in_copies false           # Use symlinks when possible

# Batch processing
--batch_size 50                   # Process in batches
--parallel_uploads 4              # Parallel GCS uploads
```

## Troubleshooting

### Common Issues and Solutions

#### 1. **Out of Memory Errors**
```bash
# Increase memory allocation
--gubbins_memory "32 GB"
--parsnp_memory "16 GB"

# Or use ClonalFrameML instead
--recombination clonalframeml
```

#### 2. **Preemption Issues**
```bash
# Check preemption status in logs
# Consider non-preemptible for critical steps
--use_preemptible false

# Or increase retry attempts
--aggressive_retry true
```

#### 3. **Cost Overruns**
```bash
# Set strict budget limits
--max_estimated_cost 50.0

# Use more aggressive optimizations
--skip_recombination_large_datasets true
--use_fast_tree_only true
```

#### 4. **Slow Performance**
```bash
# Check if using optimal machine types
# Monitor resource usage
--monitor_resource_usage true

# Consider batch processing for large datasets
--batch_size 100
```

### Debug Mode
For troubleshooting, enable debug mode:

```bash
nextflow run bacterial-genomics/wf-assembly-snps \
    -profile gcp_minimal \
    --debug_mode true \
    --verbose_logging true \
    --monitor_resource_usage true \
    --input gs://your-bucket/input/ \
    --outdir gs://your-bucket/results/
```

## Cost Estimation

### Expected Costs by Dataset Size

| Genomes | ClonalFrameML | Gubbins | No Recombination |
|---------|---------------|---------|------------------|
| 50      | $5-10         | $15-25  | $3-5             |
| 100     | $10-20        | $30-50  | $5-10            |
| 200     | $20-40        | $60-100 | $10-20           |
| 500     | $50-100       | $150-300| $25-50           |
| 1000    | $100-200      | $300-600| $50-100          |

*Costs assume preemptible instances and us-central1 region*

## Best Practices

### 1. **Data Organization**
```bash
# Organize input data efficiently
gs://your-bucket/
├── input/
│   ├── genome1.fasta
│   ├── genome2.fasta
│   └── ...
├── results/
└── work/  # Optional work directory
```

### 2. **Batch Processing**
For very large datasets (>500 genomes), consider processing in batches:

```bash
# Process in batches of 200
for batch in batch1 batch2 batch3; do
    nextflow run bacterial-genomics/wf-assembly-snps \
        -profile gcp_minimal \
        --input gs://your-bucket/input/$batch/ \
        --outdir gs://your-bucket/results/$batch/ \
        --recombination clonalframeml
done
```

### 3. **Resource Monitoring**
Always monitor your runs:

```bash
# Check GCP console for:
# - Compute Engine instances
# - Cloud Storage usage
# - Billing dashboard
# - Budget alerts
```

### 4. **Cost Controls**
Set up budget alerts in GCP Console:
1. Go to Billing → Budgets & alerts
2. Create budget with your expected cost
3. Set alerts at 50%, 90%, and 100%

## Setup Instructions

### 1. **Run the Setup Script**
```bash
# Make the script executable
chmod +x bin/setup_gcp.sh

# Run interactive setup
./bin/setup_gcp.sh

# Or with parameters
./bin/setup_gcp.sh -p your-project-id -b your-bucket-name
```

### 2. **Manual Setup**
```bash
# Set environment variables
export GOOGLE_CLOUD_PROJECT="your-project-id"
export NXF_MODE=google

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable lifesciences.googleapis.com

# Create storage bucket
gsutil mb gs://your-bucket-name
```

## Support and Optimization Services

For additional optimization or support:
1. **GCP Cost Optimization**: Use GCP's cost optimization tools
2. **Nextflow Tower**: Consider Nextflow Tower for workflow management
3. **Custom Optimization**: Contact for dataset-specific optimizations

## Contributing

To contribute improvements to the GCP optimization:
1. Fork the repository
2. Create optimization branch
3. Test with various dataset sizes
4. Submit pull request with cost/performance benchmarks