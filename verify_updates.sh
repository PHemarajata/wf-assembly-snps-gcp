#!/bin/bash

# Verification Script for wf-assembly-snps-gcp Updates
# Checks if the ClonalFrameML and Spot VM fixes were applied correctly

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
echo -e "${BLUE}    Pipeline Update Verification       ${NC}"
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

print_info "Checking ClonalFrameML fixes..."

# 1. Check ClonalFrameML timeout fix
check_content \
    "modules/local/recombination_clonalframeml/main.nf" \
    "timeout 4h ClonalFrameML" \
    "ClonalFrameML timeout mechanism"

# 2. Check ClonalFrameML enhanced debugging
check_content \
    "modules/local/recombination_clonalframeml/main.nf" \
    "=== ClonalFrameML Debug Info ===" \
    "ClonalFrameML enhanced debugging"

# 3. Check ClonalFrameML input validation
check_content \
    "modules/local/recombination_clonalframeml/main.nf" \
    "if \[ ! -f.*core_alignment_fasta" \
    "ClonalFrameML input validation"

# 4. Check ClonalFrameML container update
check_content \
    "modules/local/recombination_clonalframeml/main.nf" \
    "snads/clonalframeml:1.12" \
    "ClonalFrameML container update"

echo ""
print_info "Checking Spot VM migration..."

# 5. Check use_spot parameter
check_content \
    "conf/gcp_params.config" \
    "use_spot.*= true" \
    "Spot VM parameter added"

# 6. Check backward compatibility
check_content \
    "conf/gcp_params.config" \
    "use_preemptible.*= true.*# Deprecated" \
    "Backward compatibility maintained"

# 7. Check GCB profile Spot configuration
check_content \
    "conf/profiles/gcb.config" \
    "spot = params.use_spot.*params.use_preemptible" \
    "GCB profile Spot VM configuration"

# 8. Check GCP minimal profile Spot configuration
check_content \
    "conf/profiles/gcp_minimal.config" \
    "spot = params.use_spot.*params.use_preemptible" \
    "GCP minimal profile Spot VM configuration"

echo ""
print_info "Checking resource enhancements..."

# 9. Check ClonalFrameML resource scaling in GCB
check_content \
    "conf/profiles/gcb.config" \
    "withName:RECOMBINATION_CLONALFRAMEML" \
    "ClonalFrameML resource configuration (GCB)"

# 10. Check ClonalFrameML retry strategy
check_content \
    "conf/profiles/gcb.config" \
    "task.exitStatus == 124.*# Timeout" \
    "ClonalFrameML timeout retry strategy"

# 11. Check ClonalFrameML memory scaling
check_content \
    "conf/profiles/gcb.config" \
    "if (task.attempt == 1)" \
    "ClonalFrameML resource scaling"

echo ""
print_info "Checking documentation updates..."

# 12. Check README Spot VM updates
check_content \
    "README.md" \
    "--use_spot true" \
    "README Spot VM parameter usage" \
    "false"

# 13. Check README cost optimization update
check_content \
    "README.md" \
    "Spot instances and algorithm optimization" \
    "README cost optimization description" \
    "false"

# 14. Check README troubleshooting update
check_content \
    "README.md" \
    "ClonalFrameML Hanging.*Fixed with enhanced error handling" \
    "README troubleshooting update" \
    "false"

echo ""
print_info "Checking additional files..."

# 15. Check if update summary exists
if [[ -f "UPDATE_SUMMARY.md" ]] || [[ -f "FIXES_SUMMARY.md" ]]; then
    print_status "Update summary documentation exists"
    ((verification_passed++))
else
    print_warning "Update summary documentation not found"
fi

# 16. Check if patches directory exists
if [[ -d "patches" ]]; then
    print_status "Patches directory exists"
    ((verification_passed++))
    
    # Count patch files
    patch_count=$(find patches -name "*.patch" -type f | wc -l)
    if [[ $patch_count -ge 4 ]]; then
        print_status "All patch files present ($patch_count found)"
        ((verification_passed++))
    else
        print_warning "Some patch files missing ($patch_count found, expected 4)"
    fi
else
    print_warning "Patches directory not found"
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
    echo -e "${GREEN}🎉 All verifications passed!${NC}"
    echo ""
    echo "Your pipeline has been successfully updated with:"
    echo "✅ ClonalFrameML hanging fix"
    echo "✅ Spot VM migration"
    echo "✅ Enhanced resource management"
    echo "✅ Improved error handling"
    echo ""
    echo "You can now use:"
    echo "• --use_spot true (recommended)"
    echo "• --recombination clonalframeml (should work reliably)"
    echo ""
    echo "Next steps:"
    echo "1. Test with a small dataset"
    echo "2. Monitor ClonalFrameML execution"
    echo "3. Verify cost savings with Spot instances"
    
elif [[ $verification_failed -le 3 ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  Minor issues detected${NC}"
    echo ""
    echo "Most updates appear to be applied correctly."
    echo "Some optional components may be missing."
    echo ""
    echo "Recommendations:"
    echo "1. Review failed checks above"
    echo "2. Test core functionality (ClonalFrameML and Spot VMs)"
    echo "3. Apply missing patches if needed"
    
else
    echo ""
    echo -e "${RED}❌ Significant issues detected${NC}"
    echo ""
    echo "Several critical updates appear to be missing."
    echo ""
    echo "Recommendations:"
    echo "1. Re-run the update script: ./update_pipeline.sh"
    echo "2. Apply patches manually: ./apply_patches.sh"
    echo "3. Check for file conflicts or permissions issues"
    echo "4. Consider using rollback script if needed: ./rollback_updates.sh"
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