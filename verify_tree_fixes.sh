#!/bin/bash

# Verification Script for Tree Building Fixes
# Checks if all the tree building fixes have been applied correctly

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Tree Building Fixes Verification   ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if we're in the right directory
if [[ ! -f "main.nf" ]] || [[ ! -d "modules" ]]; then
    print_error "This doesn't appear to be a Nextflow pipeline directory"
    exit 1
fi

verification_passed=0
verification_failed=0

# Function to check file content
check_content() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    local required="${4:-true}"
    
    if [[ ! -f "$file" ]]; then
        if [[ "$required" == "true" ]]; then
            print_error "$description - File not found: $file"
            ((verification_failed++))
        else
            print_warning "$description - Optional file not found: $file"
        fi
        return 1
    fi
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        print_status "$description"
        ((verification_passed++))
        return 0
    else
        print_error "$description - Pattern not found: $pattern"
        ((verification_failed++))
        return 1
    fi
}

print_info "Checking tree building module fixes..."

# 1. Check file naming fix
check_content \
    "modules/local/build_phylogenetic_tree_parsnp/main.nf" \
    "def tree_file.*Final.tree" \
    "Tree file naming consistency fix"

# 2. Check timeout implementation
check_content \
    "modules/local/build_phylogenetic_tree_parsnp/main.nf" \
    "timeout.*fasttree" \
    "FastTree timeout protection"

# 3. Check RaxML timeout
check_content \
    "modules/local/build_phylogenetic_tree_parsnp/main.nf" \
    "timeout.*raxmlHPC-PTHREADS" \
    "RaxML timeout protection"

# 4. Check debugging output
check_content \
    "modules/local/build_phylogenetic_tree_parsnp/main.nf" \
    "=== Tree Building Debug Info ===" \
    "Enhanced debugging output"

# 5. Check input validation
check_content \
    "modules/local/build_phylogenetic_tree_parsnp/main.nf" \
    "if \[ ! -f.*masked_alignment" \
    "Input file validation"

# 6. Check error handling
check_content \
    "modules/local/build_phylogenetic_tree_parsnp/main.nf" \
    "FastTree failed with exit code" \
    "Enhanced error handling"

echo ""
print_info "Checking resource configuration..."

# 7. Check GCB profile tree building config
check_content \
    "conf/profiles/gcb.config" \
    "withName:BUILD_PHYLOGENETIC_TREE_PARSNP" \
    "GCB profile tree building configuration"

# 8. Check compute-optimized machine type
check_content \
    "conf/profiles/gcb.config" \
    "machineType = 'c2-standard-8'" \
    "Compute-optimized machine type (GCB)"

# 9. Check memory scaling
check_content \
    "conf/profiles/gcb.config" \
    "if (task.attempt == 1)" \
    "Memory scaling on retries (GCB)"

# 10. Check GCP minimal profile
check_content \
    "conf/profiles/gcp_minimal.config" \
    "withName:BUILD_PHYLOGENETIC_TREE_PARSNP" \
    "GCP minimal profile tree building configuration"

# 11. Check timeout retry strategy
check_content \
    "conf/profiles/gcb.config" \
    "task.exitStatus == 124.*# Timeout" \
    "Timeout retry strategy"

echo ""
print_info "Checking QC improvements..."

# 12. Check minimum file size increase
check_content \
    "modules/local/build_phylogenetic_tree_parsnp/params.config" \
    "min_tree_filesize = '100c'" \
    "Increased minimum tree file size"

# 13. Check tree method default
check_content \
    "modules/local/core_genome_alignment_parsnp/params.config" \
    "tree_method.*fasttree" \
    "Default tree method (FastTree)"

echo ""
print_info "Checking script syntax..."

# 14. Check for script vs shell directive
check_content \
    "modules/local/build_phylogenetic_tree_parsnp/main.nf" \
    "script:" \
    "Using script directive (not shell)"

# 15. Check for proper variable interpolation
check_content \
    "modules/local/build_phylogenetic_tree_parsnp/main.nf" \
    '\${tree_file}' \
    "Proper variable interpolation"

echo ""
print_info "Checking documentation..."

# 16. Check if fixes documentation exists
if [[ -f "TREE_BUILDING_FIXES.md" ]]; then
    print_status "Tree building fixes documentation exists"
    ((verification_passed++))
else
    print_warning "Tree building fixes documentation not found"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}         Verification Summary           ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo "Checks passed: $verification_passed"
echo "Checks failed: $verification_failed"
echo "Total checks: $((verification_passed + verification_failed))"

if [[ $verification_failed -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}🎉 All tree building fixes verified!${NC}"
    echo ""
    echo "Your pipeline should now:"
    echo "✅ Build trees without hanging"
    echo "✅ Produce proper tree output files"
    echo "✅ Have enhanced error handling and debugging"
    echo "✅ Use compute-optimized resources"
    echo "✅ Automatically retry on failures"
    echo ""
    echo "Next steps:"
    echo "1. Test with your dataset: nextflow run . -profile gcb --input snp_test.csv ..."
    echo "2. Monitor logs for detailed progress information"
    echo "3. Check that tree files are produced in the output directory"
    
elif [[ $verification_failed -le 3 ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  Minor issues detected${NC}"
    echo ""
    echo "Most fixes appear to be applied correctly."
    echo "Some optional components may be missing."
    echo ""
    echo "Recommendations:"
    echo "1. Review failed checks above"
    echo "2. Test core functionality (tree building)"
    echo "3. Apply missing fixes if needed"
    
else
    echo ""
    echo -e "${RED}❌ Significant issues detected${NC}"
    echo ""
    echo "Several critical fixes appear to be missing."
    echo ""
    echo "Recommendations:"
    echo "1. Review the TREE_BUILDING_FIXES.md document"
    echo "2. Apply fixes manually"
    echo "3. Re-run this verification script"
fi

echo ""
print_info "Verification completed!"

# Exit with appropriate code
if [[ $verification_failed -eq 0 ]]; then
    exit 0
elif [[ $verification_failed -le 3 ]]; then
    exit 1
else
    exit 2
fi