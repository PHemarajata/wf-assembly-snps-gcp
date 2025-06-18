# Pipeline Patches and Update Scripts

This directory contains patches and scripts to fix critical issues in the wf-assembly-snps-gcp pipeline.

## Issues Fixed

### 1. ClonalFrameML Hanging Issue ✅
- **Problem**: ClonalFrameML tasks were getting stuck with no activity
- **Solution**: Enhanced error handling, timeout mechanism, better resource allocation

### 2. Preemptible → Spot VM Migration ✅
- **Problem**: Google deprecated preemptible VMs in favor of Spot VMs
- **Solution**: Updated parameter names with backward compatibility

## Files in This Directory

### Update Scripts
- `update_pipeline.sh` - **Main update script** (recommended)
- `apply_patches.sh` - Apply individual patches
- `rollback_updates.sh` - Rollback changes if needed

### Patch Files
- `01-clonalframeml-fix.patch` - Fixes ClonalFrameML hanging issue
- `02-spot-vm-migration.patch` - Migrates from preemptible to Spot VMs
- `03-config-updates.patch` - Enhanced resource configuration
- `04-documentation-updates.patch` - Updates documentation

## Quick Start

### Option 1: Use the Main Update Script (Recommended)
```bash
# Make executable and run
chmod +x update_pipeline.sh
./update_pipeline.sh
```

### Option 2: Apply Individual Patches
```bash
# Make executable and run
chmod +x apply_patches.sh
./apply_patches.sh
```

### Option 3: Manual Patch Application
```bash
# Apply patches manually
patch -p1 < patches/01-clonalframeml-fix.patch
patch -p1 < patches/02-spot-vm-migration.patch
patch -p1 < patches/03-config-updates.patch
patch -p1 < patches/04-documentation-updates.patch
```

## What Gets Changed

### Files Modified
- `modules/local/recombination_clonalframeml/main.nf` - ClonalFrameML process fix
- `conf/gcp_params.config` - New Spot VM parameters
- `conf/profiles/gcb.config` - Updated GCP Batch configuration
- `conf/profiles/gcp_minimal.config` - Updated minimal GCP configuration
- `README.md` - Documentation updates

### Key Changes
1. **ClonalFrameML Process**:
   - Added 4-hour timeout to prevent hanging
   - Enhanced error handling and debugging
   - Better resource allocation (4 CPU, 16GB RAM)
   - Input validation and comprehensive logging

2. **Spot VM Support**:
   - New `--use_spot` parameter (replaces `--use_preemptible`)
   - Backward compatibility maintained
   - Updated all GCP profiles

3. **Enhanced Resource Management**:
   - Automatic resource scaling on retry
   - Better error classification and retry strategies
   - Improved machine type selection

## Usage After Updates

### New Recommended Syntax
```bash
nextflow run . \
    -profile gcb \
    --input gs://your-bucket/input/ \
    --outdir gs://your-bucket/results/ \
    --recombination clonalframeml \
    --use_spot true
```

### Backward Compatible (Still Works)
```bash
nextflow run . \
    -profile gcb \
    --input gs://your-bucket/input/ \
    --outdir gs://your-bucket/results/ \
    --recombination clonalframeml \
    --use_preemptible true  # Deprecated but still works
```

## Rollback Instructions

If you need to undo the changes:

### Option 1: Use Rollback Script
```bash
chmod +x rollback_updates.sh
./rollback_updates.sh
```

### Option 2: Manual Rollback
```bash
# Restore from backups (if available)
find . -name "*.backup.*" -type f

# Or use git (if available)
git checkout HEAD -- modules/local/recombination_clonalframeml/main.nf
git checkout HEAD -- conf/
```

## Testing

After applying updates, test with:

```bash
# Test ClonalFrameML specifically
nextflow run . \
    -profile test \
    --recombination clonalframeml \
    --use_spot true

# Monitor for hanging issues
tail -f work/*/clonalframeml/.command.log
```

## Troubleshooting

### Common Issues

1. **Patch doesn't apply cleanly**
   - Files may already be modified
   - Use `--force` option or apply manually

2. **Permission denied**
   - Make scripts executable: `chmod +x *.sh`

3. **Git conflicts**
   - Commit changes before applying patches
   - Or use backup restoration method

### Getting Help

1. Check `UPDATE_SUMMARY.md` for detailed changes
2. Review individual patch files for specific modifications
3. Use rollback script if issues occur
4. Test with small datasets first

## Verification

After applying patches, verify:

```bash
# Check ClonalFrameML timeout is present
grep -n "timeout 4h" modules/local/recombination_clonalframeml/main.nf

# Check Spot VM parameter exists
grep -n "use_spot" conf/gcp_params.config

# Check backward compatibility
grep -n "use_spot.*use_preemptible" conf/profiles/gcb.config
```

## Support

- **ClonalFrameML Issues**: Check enhanced logging in work directories
- **Spot VM Issues**: Verify GCP project has Spot VM quota
- **Patch Issues**: Use rollback script and apply manually

---

**Last Updated**: $(date)
**Pipeline Version**: wf-assembly-snps-gcp
**Patch Version**: 1.0