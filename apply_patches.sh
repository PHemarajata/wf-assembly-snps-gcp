#!/bin/bash

# Apply Patches Script for wf-assembly-snps-gcp
# This script applies individual patches for the pipeline fixes

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [[ ! -f "main.nf" ]] || [[ ! -d "modules" ]]; then
    print_error "This doesn't appear to be a Nextflow pipeline directory"
    print_error "Please run this script from the pipeline root directory"
    exit 1
fi

# Check if patches directory exists
if [[ ! -d "patches" ]]; then
    print_error "Patches directory not found"
    print_error "Please ensure the patches directory exists with the patch files"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Applying Pipeline Patches          ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to apply a single patch
apply_patch() {
    local patch_file="$1"
    local description="$2"
    local required="${3:-true}"
    
    if [[ ! -f "$patch_file" ]]; then
        if [[ "$required" == "true" ]]; then
            print_error "Required patch file not found: $patch_file"
            return 1
        else
            print_warning "Optional patch file not found: $patch_file (skipping)"
            return 0
        fi
    fi
    
    print_status "Applying: $description"
    
    # Test if patch can be applied
    if patch -p1 --dry-run --silent < "$patch_file" > /dev/null 2>&1; then
        # Apply the patch
        if patch -p1 < "$patch_file" > /dev/null 2>&1; then
            print_status "✅ Successfully applied: $description"
            return 0
        else
            print_error "❌ Failed to apply: $description"
            return 1
        fi
    else
        print_warning "⚠️  Patch may not apply cleanly: $description"
        echo "   This might mean the changes are already applied or there are conflicts."
        echo "   Would you like to force apply this patch? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            if patch -p1 --force < "$patch_file" > /dev/null 2>&1; then
                print_warning "⚠️  Force applied: $description"
                return 0
            else
                print_error "❌ Failed to force apply: $description"
                return 1
            fi
        else
            print_warning "⏭️  Skipped: $description"
            return 0
        fi
    fi
}

# Create backups before applying patches
print_status "Creating backups..."
backup_dir="backups_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

files_to_backup=(
    "modules/local/recombination_clonalframeml/main.nf"
    "conf/gcp_params.config"
    "conf/profiles/gcb.config"
    "conf/profiles/gcp_minimal.config"
    "README.md"
)

for file in "${files_to_backup[@]}"; do
    if [[ -f "$file" ]]; then
        cp "$file" "$backup_dir/"
        print_status "Backed up: $file"
    fi
done

echo ""
print_status "Starting patch application..."

# Apply patches in order
patches_applied=0
patches_failed=0

# 1. ClonalFrameML fix
if apply_patch "patches/01-clonalframeml-fix.patch" "ClonalFrameML hanging fix"; then
    ((patches_applied++))
else
    ((patches_failed++))
fi

# 2. Spot VM migration
if apply_patch "patches/02-spot-vm-migration.patch" "Preemptible to Spot VM migration"; then
    ((patches_applied++))
else
    ((patches_failed++))
fi

# 3. Configuration updates
if apply_patch "patches/03-config-updates.patch" "Enhanced resource configuration"; then
    ((patches_applied++))
else
    ((patches_failed++))
fi

# 4. Documentation updates
if apply_patch "patches/04-documentation-updates.patch" "Documentation updates" "false"; then
    ((patches_applied++))
else
    ((patches_failed++))
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}         Patch Summary                  ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Patches applied: $patches_applied"
echo "Patches failed: $patches_failed"
echo "Backups created in: $backup_dir"

if [[ $patches_failed -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}✅ All patches applied successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Test the pipeline with a small dataset"
    echo "2. Use --use_spot true instead of --use_preemptible true"
    echo "3. ClonalFrameML should now work without hanging"
    
    # Verify critical files
    print_status "Verifying patched files..."
    
    if grep -q "timeout 4h ClonalFrameML" "modules/local/recombination_clonalframeml/main.nf" 2>/dev/null; then
        print_status "✅ ClonalFrameML timeout fix verified"
    else
        print_warning "⚠️  ClonalFrameML timeout fix not detected"
    fi
    
    if grep -q "use_spot" "conf/gcp_params.config" 2>/dev/null; then
        print_status "✅ Spot VM parameter verified"
    else
        print_warning "⚠️  Spot VM parameter not detected"
    fi
    
    if grep -q "params.use_spot.*params.use_preemptible" "conf/profiles/gcb.config" 2>/dev/null; then
        print_status "✅ Backward compatibility verified"
    else
        print_warning "⚠️  Backward compatibility not detected"
    fi
    
else
    echo ""
    echo -e "${YELLOW}⚠️  Some patches failed to apply${NC}"
    echo ""
    echo "This might be because:"
    echo "1. Changes are already applied"
    echo "2. Files have been modified differently"
    echo "3. Patch conflicts exist"
    echo ""
    echo "You can:"
    echo "1. Review the failed patches manually"
    echo "2. Restore from backups in $backup_dir if needed"
    echo "3. Apply changes manually using the patch files as reference"
fi

echo ""
print_status "Patch application completed!"