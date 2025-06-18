#!/bin/bash

# Rollback Script for wf-assembly-snps-gcp Updates
# This script helps rollback the ClonalFrameML and Spot VM fixes

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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Pipeline Rollback Script           ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if we're in the right directory
if [[ ! -f "main.nf" ]] || [[ ! -d "modules" ]]; then
    print_error "This doesn't appear to be a Nextflow pipeline directory"
    print_error "Please run this script from the pipeline root directory"
    exit 1
fi

# Function to find backup files
find_backups() {
    local file="$1"
    find . -name "$(basename "$file").backup.*" -type f 2>/dev/null | sort -r
}

# Function to restore from backup
restore_from_backup() {
    local file="$1"
    local backups
    
    backups=$(find_backups "$file")
    
    if [[ -z "$backups" ]]; then
        print_warning "No backup found for: $file"
        return 1
    fi
    
    echo "Available backups for $file:"
    local i=1
    local backup_array=()
    while IFS= read -r backup; do
        echo "  $i) $backup"
        backup_array+=("$backup")
        ((i++))
    done <<< "$backups"
    
    echo "  0) Skip this file"
    echo ""
    echo -n "Select backup to restore (0-$((i-1))): "
    read -r choice
    
    if [[ "$choice" == "0" ]]; then
        print_status "Skipped: $file"
        return 0
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -lt "$i" ]]; then
        local selected_backup="${backup_array[$((choice-1))]}"
        if cp "$selected_backup" "$file"; then
            print_status "✅ Restored: $file from $selected_backup"
            return 0
        else
            print_error "❌ Failed to restore: $file"
            return 1
        fi
    else
        print_error "Invalid choice: $choice"
        return 1
    fi
}

# Function to restore from git
restore_from_git() {
    local file="$1"
    
    if ! command -v git &> /dev/null; then
        print_warning "Git not available"
        return 1
    fi
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_warning "Not a git repository"
        return 1
    fi
    
    if git checkout HEAD -- "$file" 2>/dev/null; then
        print_status "✅ Restored from git: $file"
        return 0
    else
        print_warning "Failed to restore from git: $file"
        return 1
    fi
}

# Files that were modified
modified_files=(
    "modules/local/recombination_clonalframeml/main.nf"
    "conf/gcp_params.config"
    "conf/profiles/gcb.config"
    "conf/profiles/gcp_minimal.config"
    "README.md"
)

echo "This script will help you rollback the following changes:"
echo "• ClonalFrameML hanging fix"
echo "• Preemptible to Spot VM migration"
echo "• Enhanced resource configuration"
echo "• Documentation updates"
echo ""

# Check what rollback options are available
backup_available=false
git_available=false

# Check for backup files
for file in "${modified_files[@]}"; do
    if [[ -n "$(find_backups "$file")" ]]; then
        backup_available=true
        break
    fi
done

# Check for git
if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    git_available=true
fi

if [[ "$backup_available" == "false" ]] && [[ "$git_available" == "false" ]]; then
    print_error "No rollback options available!"
    print_error "Neither backup files nor git repository found."
    echo ""
    echo "Manual rollback options:"
    echo "1. Re-clone the original repository"
    echo "2. Manually edit the files to remove changes"
    echo "3. Use version control if available"
    exit 1
fi

echo "Available rollback methods:"
if [[ "$backup_available" == "true" ]]; then
    echo "1) Restore from backup files"
fi
if [[ "$git_available" == "true" ]]; then
    echo "2) Restore from git (HEAD)"
fi
echo "0) Cancel"
echo ""

echo -n "Select rollback method: "
read -r method

case "$method" in
    1)
        if [[ "$backup_available" == "false" ]]; then
            print_error "Backup files not available"
            exit 1
        fi
        
        print_status "Rolling back using backup files..."
        echo ""
        
        for file in "${modified_files[@]}"; do
            if [[ -f "$file" ]]; then
                echo "Processing: $file"
                restore_from_backup "$file"
                echo ""
            else
                print_warning "File not found: $file"
            fi
        done
        ;;
        
    2)
        if [[ "$git_available" == "false" ]]; then
            print_error "Git not available"
            exit 1
        fi
        
        print_status "Rolling back using git..."
        echo ""
        
        # Show what will be changed
        echo "Files that will be restored from git:"
        for file in "${modified_files[@]}"; do
            if git diff --name-only HEAD -- "$file" 2>/dev/null | grep -q "$file"; then
                echo "  • $file"
            fi
        done
        echo ""
        
        echo "Continue with git rollback? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_status "Rollback cancelled"
            exit 0
        fi
        
        for file in "${modified_files[@]}"; do
            restore_from_git "$file"
        done
        ;;
        
    0)
        print_status "Rollback cancelled"
        exit 0
        ;;
        
    *)
        print_error "Invalid choice: $method"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}         Rollback Complete              ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Verify rollback
print_status "Verifying rollback..."

# Check if ClonalFrameML timeout is removed
if ! grep -q "timeout 4h ClonalFrameML" "modules/local/recombination_clonalframeml/main.nf" 2>/dev/null; then
    print_status "✅ ClonalFrameML timeout fix removed"
else
    print_warning "⚠️  ClonalFrameML timeout fix still present"
fi

# Check if use_spot parameter is removed
if ! grep -q "use_spot" "conf/gcp_params.config" 2>/dev/null; then
    print_status "✅ Spot VM parameters removed"
else
    print_warning "⚠️  Spot VM parameters still present"
fi

echo ""
echo "Rollback completed! Your pipeline has been restored to the previous state."
echo ""
echo "Note: You may need to:"
echo "1. Test the pipeline to ensure it works as expected"
echo "2. Use --use_preemptible true (old parameter) instead of --use_spot true"
echo "3. Be aware that ClonalFrameML may hang again without the fixes"
echo ""
print_status "Rollback process finished!"