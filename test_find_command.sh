#!/bin/bash

# Test script to check if the find command works with 'c' suffix

echo "🧪 Testing find command with size specifications"
echo "==============================================="

# Create a test file
echo "This is a test file with more than 100 characters to test the find command size specification functionality." > test_file.txt

file_size=$(wc -c < test_file.txt)
echo "Test file size: $file_size bytes"
echo ""

# Test different size specifications
echo "Testing find command with different size specs:"
echo ""

echo "1. find test_file.txt -size +100c"
if find test_file.txt -size +100c 2>/dev/null | grep -q test_file.txt; then
    echo "   ✅ FOUND (100c works)"
else
    echo "   ❌ NOT FOUND (100c doesn't work)"
fi

echo "2. find test_file.txt -size +100"
if find test_file.txt -size +100 2>/dev/null | grep -q test_file.txt; then
    echo "   ✅ FOUND (100 works)"
else
    echo "   ❌ NOT FOUND (100 doesn't work)"
fi

echo "3. find test_file.txt -size +50c"
if find test_file.txt -size +50c 2>/dev/null | grep -q test_file.txt; then
    echo "   ✅ FOUND (50c works)"
else
    echo "   ❌ NOT FOUND (50c doesn't work)"
fi

echo ""
echo "📝 Note: The 'c' suffix in find means bytes, not characters"
echo "   Your 1.33kb file = 1330 bytes, which is much larger than 100c (100 bytes)"
echo ""

# Clean up
rm -f test_file.txt

echo "🔍 Recommendation:"
echo "   The issue might be in the bash_functions.sh verify_minimum_file_size function"
echo "   or in how the file path is being constructed in the tree building script."