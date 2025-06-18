# Tree Building Fixes for wf-assembly-snps-gcp

## Issues Identified

From your log analysis, the `BUILD_PHYLOGENETIC_TREE_PARSNP` process was:
1. **Taking too long** (over 1 hour for a small dataset)
2. **Not producing expected output** ("Skipping output binding because one or more optional files are missing")
3. **Completing with exit 0** but failing QC checks

## Root Causes Found

### 1. **File Naming Bug** 🐛
- **Problem**: Script creates `*.Final.tree` but verifies `*.tree` (missing `.Final`)
- **Impact**: QC check fails because it looks for wrong filename
- **Fix**: Corrected file naming consistency in the script

### 2. **Inadequate Error Handling** ⚠️
- **Problem**: No timeout, poor debugging, silent failures
- **Impact**: Process hangs indefinitely without clear error messages
- **Fix**: Added comprehensive error handling, timeouts, and debugging

### 3. **Insufficient Resources** 💾
- **Problem**: Tree building is CPU-intensive but had generic resource allocation
- **Impact**: Slow performance, potential memory issues
- **Fix**: Dedicated resource configuration with scaling

### 4. **Too Strict File Size Check** 📏
- **Problem**: Minimum tree file size was only 1 character
- **Impact**: Even tiny/invalid trees would pass QC
- **Fix**: Increased to 100 characters minimum

## Fixes Applied

### 1. **Fixed Tree Building Module** ✅
**File**: `modules/local/build_phylogenetic_tree_parsnp/main.nf`

**Changes**:
- ✅ Fixed file naming inconsistency (`.Final.tree` vs `.tree`)
- ✅ Added comprehensive debugging and logging
- ✅ Added timeout protection (2h for FastTree, 4h for RaxML)
- ✅ Added input validation and error handling
- ✅ Improved QC file naming and logic
- ✅ Better version detection for tools

**Key Improvements**:
```bash
# Before: Silent failures, no debugging
fasttree -nt input.fasta > output.tree

# After: Timeout, error handling, debugging
timeout 2h fasttree -nt input.fasta > output.tree || {
    exit_code=$?
    echo "FastTree failed with exit code: $exit_code"
    if [ $exit_code -eq 124 ]; then
        echo "ERROR: FastTree timed out after 2 hours"
    fi
    exit $exit_code
}
```

### 2. **Enhanced Resource Allocation** 🚀
**Files**: `conf/profiles/gcb.config`, `conf/profiles/gcp_minimal.config`

**New Configuration**:
- **CPUs**: 8 (compute-optimized)
- **Memory**: 32 GB → 64 GB → 128 GB (scaling on retries)
- **Time**: 6h → 8h → 12h (scaling on retries)
- **Machine Type**: `c2-standard-8` (compute-optimized)
- **Retry Strategy**: Automatic retries for timeouts and OOM errors

### 3. **Improved QC Thresholds** 📊
**File**: `modules/local/build_phylogenetic_tree_parsnp/params.config`

**Changes**:
- **Before**: `min_tree_filesize = '1c'` (1 character)
- **After**: `min_tree_filesize = '100c'` (100 characters)

## Expected Improvements

### 🚀 **Performance**
- **Faster execution** with compute-optimized instances
- **Better resource utilization** with proper CPU/memory allocation
- **Automatic scaling** if initial resources insufficient

### 🛡️ **Reliability**
- **No more hanging** - timeouts prevent infinite runs
- **Clear error messages** - detailed debugging output
- **Automatic retries** - transient failures handled gracefully

### 🔍 **Debugging**
- **Comprehensive logging** - see exactly what's happening
- **Input validation** - catch problems early
- **File size reporting** - understand QC failures

## Usage Recommendations

### **For Small Datasets (<50 genomes)**
```bash
# Should complete in 10-30 minutes now
nextflow run . -profile gcb \
    --input your_samples.csv \
    --outdir results/ \
    --recombination gubbins \
    --use_spot true
```

### **For Medium Datasets (50-200 genomes)**
```bash
# Should complete in 30-90 minutes
nextflow run . -profile gcb \
    --input your_samples.csv \
    --outdir results/ \
    --recombination gubbins \
    --use_spot true
```

### **For Large Datasets (200+ genomes)**
```bash
# May take 1-3 hours, will auto-scale resources
nextflow run . -profile gcb \
    --input your_samples.csv \
    --outdir results/ \
    --recombination gubbins \
    --use_spot true
```

## Troubleshooting

### **If Tree Building Still Fails**

1. **Check the logs**:
   ```bash
   # Look for detailed debug output
   cat work/*/BUILD_PHYLOGENETIC_TREE_PARSNP/.command.log
   ```

2. **Check input alignment**:
   ```bash
   # Verify alignment file is valid
   head work/*/MASK_RECOMBINANT_POSITIONS_BIOPYTHON/*.masked.fasta
   ```

3. **Monitor resources**:
   ```bash
   # Add resource monitoring
   --monitor_resource_usage true --verbose_logging true
   ```

### **Common Issues and Solutions**

| Issue | Cause | Solution |
|-------|-------|----------|
| **Timeout after 2-4h** | Very large dataset | Will auto-retry with more time |
| **Out of memory** | Complex alignment | Will auto-retry with more memory |
| **QC failure** | Empty/invalid tree | Check input alignment quality |
| **Tool not found** | Container issue | Check container availability |

## Testing

To test the fixes:

```bash
# Test with your original dataset
nextflow run . -profile gcb \
    --input snp_test.csv \
    --outdir test_results/ \
    --recombination gubbins \
    --use_spot true \
    --verbose_logging true
```

**Expected behavior**:
- ✅ Tree building should complete in reasonable time
- ✅ Clear progress messages in logs
- ✅ Tree file should be produced and pass QC
- ✅ No "missing files" errors

---

**Status**: ✅ **Ready for Testing**
**Date**: $(date)
**Pipeline**: wf-assembly-snps-gcp
**Issue**: Tree building hanging and not producing output