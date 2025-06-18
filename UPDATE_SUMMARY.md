# Pipeline Update Summary

## Updates Applied

### 1. ClonalFrameML Hanging Fix ✅
- **Issue**: ClonalFrameML tasks were hanging with no activity
- **Fix**: Enhanced error handling, timeout mechanism, better resource allocation
- **Files Modified**: `modules/local/recombination_clonalframeml/main.nf`

### 2. Preemptible → Spot VM Migration ✅
- **Issue**: Google deprecated preemptible VMs in favor of Spot VMs
- **Fix**: Updated parameter names and configurations
- **Files Modified**: 
  - `conf/gcp_params.config`
  - `conf/profiles/gcb.config`
  - `conf/profiles/gcp_minimal.config`
  - `README.md`

### 3. Enhanced Resource Management ✅
- **Improvement**: Better resource allocation and retry strategies
- **Benefit**: More reliable execution on GCP

## New Parameters

### Recommended (New)
- `--use_spot true` - Use Spot instances (replaces preemptible)

### Deprecated (Still Works)
- `--use_preemptible true` - Kept for backward compatibility

## Usage Examples

### New Recommended Syntax
```bash
nextflow run . \
    -profile gcb \
    --input gs://your-bucket/input/ \
    --outdir gs://your-bucket/results/ \
    --recombination clonalframeml \
    --use_spot true
```

### Backward Compatible
```bash
nextflow run . \
    -profile gcb \
    --input gs://your-bucket/input/ \
    --outdir gs://your-bucket/results/ \
    --recombination clonalframeml \
    --use_preemptible true  # Still works
```

## Testing Recommendations

1. Test ClonalFrameML with a small dataset
2. Verify Spot instances are working correctly
3. Check that cost optimization is maintained

## Rollback Instructions

If you need to rollback these changes:

1. Restore from backups:
   ```bash
   # Find backup files
   find . -name "*.backup.*" -type f
   
   # Restore specific file (example)
   cp modules/local/recombination_clonalframeml/main.nf.backup.YYYYMMDD_HHMMSS \
      modules/local/recombination_clonalframeml/main.nf
   ```

2. Or use git (if available):
   ```bash
   git checkout HEAD -- modules/local/recombination_clonalframeml/main.nf
   git checkout HEAD -- conf/
   ```

---
**Update Date**: $(date)
**Status**: ✅ Complete
