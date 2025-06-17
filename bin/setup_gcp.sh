#!/bin/bash

# GCP Setup Script for wf-assembly-snps-gcp Pipeline
# This script helps set up the Google Cloud Platform environment for optimal pipeline execution

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PROJECT_ID=""
REGION="us-central1"
ZONE="us-central1-a"
BUCKET_NAME=""
SERVICE_ACCOUNT_NAME="nextflow-pipeline-sa"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    if ! command_exists gcloud; then
        print_error "Google Cloud SDK (gcloud) is not installed."
        print_error "Please install it from: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    if ! command_exists nextflow; then
        print_warning "Nextflow is not installed. Installing via conda/mamba is recommended."
        print_warning "Install with: conda install -c bioconda nextflow"
    fi
    
    if ! command_exists docker; then
        print_warning "Docker is not installed. It's required for running containers."
        print_warning "Install from: https://docs.docker.com/get-docker/"
    fi
    
    print_status "Prerequisites check completed"
}

# Function to get user input
get_user_input() {
    print_header "Configuration Setup"
    
    # Get project ID
    if [ -z "$PROJECT_ID" ]; then
        echo -n "Enter your GCP Project ID: "
        read -r PROJECT_ID
    fi
    
    # Get bucket name
    if [ -z "$BUCKET_NAME" ]; then
        echo -n "Enter a unique bucket name for pipeline data (e.g., ${PROJECT_ID}-genomics-pipeline): "
        read -r BUCKET_NAME
    fi
    
    # Confirm region
    echo -n "Enter preferred region [$REGION]: "
    read -r input_region
    if [ -n "$input_region" ]; then
        REGION="$input_region"
        ZONE="${REGION}-a"
    fi
    
    print_status "Configuration collected"
}

# Function to set up GCP project
setup_gcp_project() {
    print_header "Setting up GCP Project"
    
    # Set the project
    print_status "Setting project to $PROJECT_ID"
    gcloud config set project "$PROJECT_ID"
    
    # Enable required APIs
    print_status "Enabling required APIs..."
    gcloud services enable compute.googleapis.com
    gcloud services enable storage.googleapis.com
    gcloud services enable batch.googleapis.com
    gcloud services enable logging.googleapis.com
    gcloud services enable monitoring.googleapis.com
    
    print_status "APIs enabled successfully"
}

# Function to create storage bucket
create_storage_bucket() {
    print_header "Creating Storage Bucket"
    
    # Check if bucket already exists
    if gsutil ls -b "gs://$BUCKET_NAME" >/dev/null 2>&1; then
        print_warning "Bucket gs://$BUCKET_NAME already exists"
    else
        print_status "Creating bucket gs://$BUCKET_NAME in region $REGION"
        gsutil mb -p "$PROJECT_ID" -c STANDARD -l "$REGION" "gs://$BUCKET_NAME"
        
        # Set up bucket structure
        print_status "Setting up bucket structure"
        echo "# Bacterial Genomics Pipeline Data" | gsutil cp - "gs://$BUCKET_NAME/README.txt"
        
        # Create directories
        for dir in input results work logs; do
            echo "Directory for $dir" | gsutil cp - "gs://$BUCKET_NAME/$dir/.gitkeep"
        done
    fi
    
    print_status "Storage bucket setup completed"
}

# Function to generate example commands
generate_examples() {
    print_header "Example Commands"
    
    cat << EOF

Your GCP environment is now set up! Here are example commands to run the pipeline:

1. SMALL DATASET (< 100 genomes):
   nextflow run bacterial-genomics/wf-assembly-snps-gcp \\
       -profile gcb \\
       --input gs://$BUCKET_NAME/input/ \\
       --outdir gs://$BUCKET_NAME/results/ \\
       --recombination clonalframeml \\
       --use_preemptible true \\
       --estimated_genome_count 50 \\
       --max_estimated_cost 25.0

2. MEDIUM DATASET (100-300 genomes):
   nextflow run bacterial-genomics/wf-assembly-snps-gcp \\
       -profile gcb \\
       --input gs://$BUCKET_NAME/input/ \\
       --outdir gs://$BUCKET_NAME/results/ \\
       --recombination clonalframeml \\
       --use_preemptible true \\
       --estimated_genome_count 200 \\
       --max_estimated_cost 75.0

3. LARGE DATASET (300+ genomes):
   nextflow run bacterial-genomics/wf-assembly-snps-gcp \\
       -profile gcb \\
       --input gs://$BUCKET_NAME/input/ \\
       --outdir gs://$BUCKET_NAME/results/ \\
       --recombination clonalframeml \\
       --use_preemptible true \\
       --gubbins_cpus 8 \\
       --parsnp_cpus 8 \\
       --estimated_genome_count 500 \\
       --max_estimated_cost 200.0

ENVIRONMENT VARIABLES:
export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
export NXF_MODE=google

BUCKET STRUCTURE:
gs://$BUCKET_NAME/
├── input/          # Upload your FASTA files here
├── results/        # Pipeline outputs will be stored here
├── work/           # Temporary work files (optional)
└── logs/           # Pipeline logs

NEXT STEPS:
1. Upload your FASTA files to gs://$BUCKET_NAME/input/
2. Run one of the example commands above
3. Monitor costs at: https://console.cloud.google.com/billing/
4. Check pipeline progress in Nextflow Tower (optional)

EOF
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Setup script for GCP bacterial genomics SNP pipeline

OPTIONS:
    -p, --project PROJECT_ID    GCP Project ID
    -b, --bucket BUCKET_NAME    Storage bucket name
    -r, --region REGION         GCP region (default: us-central1)
    -h, --help                  Show this help message

EXAMPLES:
    $0                          # Interactive setup
    $0 -p my-project -b my-bucket-name
    $0 --project my-project --bucket my-bucket --region us-west1

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project)
            PROJECT_ID="$2"
            shift 2
            ;;
        -b|--bucket)
            BUCKET_NAME="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            ZONE="${REGION}-a"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_header "GCP Setup for Bacterial Genomics SNP Pipeline"
    
    check_prerequisites
    get_user_input
    setup_gcp_project
    create_storage_bucket
    generate_examples
    print_status "Setup completed successfully!"
}

# Run main function
main "$@"