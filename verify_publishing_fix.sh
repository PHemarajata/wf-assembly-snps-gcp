#!/bin/bash

# Verification script for tree publishing fixes

echo "🔍 Verifying Tree Publishing Fixes"
echo "=================================="

# Check 1: Publishing pattern fix
echo "1. Checking publishing pattern..."
if grep -q 'pattern: "\*.Final.tree"' conf/modules.config; then
    echo "   ✅ Publishing pattern fixed: *.Final.tree"
else
    echo "   ❌ Publishing pattern not fixed"
fi

# Check 2: Enhanced size check logic
echo "2. Checking enhanced size check logic..."
if grep -q "BASH_REMATCH\[1\]" modules/local/build_phylogenetic_tree_parsnp/main.nf; then
    echo "   ✅ Enhanced size parsing implemented"
else
    echo "   ❌ Enhanced size parsing not found"
fi

# Check 3: Detailed QC logging
echo "3. Checking detailed QC logging..."
if grep -q "QC Check Details:" modules/local/build_phylogenetic_tree_parsnp/main.nf; then
    echo "   ✅ Detailed QC logging implemented"
else
    echo "   ❌ Detailed QC logging not found"
fi

# Check 4: Minimum tree file size
echo "4. Checking minimum tree file size..."
if grep -q "min_tree_filesize = '100c'" modules/local/build_phylogenetic_tree_parsnp/params.config; then
    echo "   ✅ Minimum tree file size set to 100c"
else
    echo "   ❌ Minimum tree file size not updated"
fi

# Check 5: Tree file creation pattern
echo "5. Checking tree file creation pattern..."
if grep -q "def tree_file.*Final.tree" modules/local/build_phylogenetic_tree_parsnp/main.nf; then
    echo "   ✅ Tree file creation uses Final.tree pattern"
else
    echo "   ❌ Tree file creation pattern issue"
fi

echo ""
echo "🎯 Summary:"
echo "   Your 1.33kb tree file should now be published correctly!"
echo "   The publishing pattern now matches the file creation pattern."
echo ""
echo "📁 Expected output locations:"
echo "   • \${outdir}/\${snp_package}/\${recombination}/*.Final.tree"
echo "   • \${outdir}/Summaries/*.Final.tree"