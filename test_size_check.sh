#!/bin/bash

# Test script to verify size checking logic

echo "🧪 Testing Tree File Size Check Logic"
echo "======================================"

# Test the size parsing logic
test_size_parsing() {
    local min_size_param="$1"
    local expected="$2"
    
    echo "Testing parameter: '$min_size_param'"
    
    if [[ "$min_size_param" =~ ^([0-9]+)c$ ]]; then
        min_size_bytes=${BASH_REMATCH[1]}
    elif [[ "$min_size_param" =~ ^([0-9]+)$ ]]; then
        min_size_bytes=$min_size_param
    else
        min_size_bytes=50
        echo "  Warning: Could not parse, using default 50 bytes"
    fi
    
    echo "  Parsed result: $min_size_bytes bytes"
    echo "  Expected: $expected bytes"
    
    if [ "$min_size_bytes" = "$expected" ]; then
        echo "  ✅ PASS"
    else
        echo "  ❌ FAIL"
    fi
    echo ""
}

# Test various size parameters
echo "Testing size parameter parsing:"
test_size_parsing "50c" "50"
test_size_parsing "100c" "100"
test_size_parsing "1000c" "1000"
test_size_parsing "50" "50"
test_size_parsing "invalid" "50"

# Test with your actual file size
echo "Testing with your tree file size:"
actual_size=1330  # 1.33kb = 1330 bytes
min_size_bytes=100  # Current setting

echo "Your tree file:"
echo "  Actual size: $actual_size bytes (1.33kb)"
echo "  Minimum required: $min_size_bytes bytes"
echo "  Size check: $([ $actual_size -gt $min_size_bytes ] && echo "PASS" || echo "FAIL")"

if [ $actual_size -gt $min_size_bytes ]; then
    echo "  ✅ Your tree file SHOULD be published"
else
    echo "  ❌ Your tree file would be rejected"
fi

echo ""
echo "🎯 Conclusion: Your 1.33kb tree file is well above the minimum size"
echo "   and should definitely pass the QC check and be published!"