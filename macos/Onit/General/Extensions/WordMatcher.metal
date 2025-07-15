//
//  WordMatcher.metal
//  Onit
//
//  Created by Alex Carmack on 2024.
//

#include <metal_stdlib>
using namespace metal;

struct WordMatcherParams {
    uint ocrCount;
    uint accessibilityCount;
    uint maxStringLength;  
    uint maxDistance;
};

// Fast string length calculation for null-terminated strings
uint string_length(const device uchar* str, uint maxLen) {
    for (uint i = 0; i < maxLen; i++) {
        if (str[i] == 0) return i;
    }
    return maxLen;
}

// Early-exit Levenshtein distance calculation optimized for GPU
uint levenshtein_distance_early_exit(const device uchar* str1, uint len1,
                                   const device uchar* str2, uint len2,
                                   uint maxDistance) {
    // Handle edge cases
    if (len1 == 0) return len2 <= maxDistance ? len2 : maxDistance + 1;
    if (len2 == 0) return len1 <= maxDistance ? len1 : maxDistance + 1;
    if (abs((int)len1 - (int)len2) > (int)maxDistance) return maxDistance + 1;
    
    // Check for exact match first
    bool exact_match = true;
    if (len1 == len2) {
        for (uint i = 0; i < len1; i++) {
            if (str1[i] != str2[i]) {
                exact_match = false;
                break;
            }
        }
        if (exact_match) return 0;
    }
    
    // Use two rows instead of full matrix to save memory
    thread uint prev_row[65]; // maxStringLength + 1
    thread uint curr_row[65];
    
    // Initialize first row
    for (uint j = 0; j <= len2; j++) {
        prev_row[j] = j;
    }
    
    // Fill the matrix row by row
    for (uint i = 1; i <= len1; i++) {
        curr_row[0] = i;
        uint row_min = i;
        
        for (uint j = 1; j <= len2; j++) {
            uint cost = (str1[i - 1] == str2[j - 1]) ? 0 : 1;
            
            uint deletion = prev_row[j] + 1;
            uint insertion = curr_row[j - 1] + 1;
            uint substitution = prev_row[j - 1] + cost;
            
            curr_row[j] = min(min(deletion, insertion), substitution);
            row_min = min(row_min, curr_row[j]);
        }
        
        // Early exit if this row's minimum exceeds threshold
        if (row_min > maxDistance) {
            return maxDistance + 1;
        }
        
        // Swap rows
        for (uint k = 0; k <= len2; k++) {
            prev_row[k] = curr_row[k];
        }
    }
    
    return prev_row[len2];
}

kernel void word_matcher_kernel(const device uchar* ocrWords [[buffer(0)]],
                              const device uchar* accessibilityWords [[buffer(1)]],
                              device uint* results [[buffer(2)]],
                              constant WordMatcherParams& params [[buffer(3)]],
                              uint gid [[thread_position_in_grid]]) {
    
    if (gid >= params.ocrCount) return;
    
    // Get the current OCR word
    const device uchar* ocrWord = ocrWords + (gid * params.maxStringLength);
    uint ocrLen = string_length(ocrWord, params.maxStringLength);
    
    // Skip empty strings
    if (ocrLen == 0) {
        results[gid] = 0;
        return;
    }
    
    // Check against all accessibility words
    bool found_match = false;
    for (uint i = 0; i < params.accessibilityCount && !found_match; i++) {
        const device uchar* accessibilityWord = accessibilityWords + (i * params.maxStringLength);
        uint accessibilityLen = string_length(accessibilityWord, params.maxStringLength);
        
        // Skip empty strings
        if (accessibilityLen == 0) continue;
        
        // Quick length check
        if (abs((int)ocrLen - (int)accessibilityLen) > (int)params.maxDistance) continue;
        
        uint distance = levenshtein_distance_early_exit(ocrWord, ocrLen, accessibilityWord, accessibilityLen, params.maxDistance);
        
        if (distance <= params.maxDistance) {
            found_match = true;
        }
    }
    
    results[gid] = found_match ? 1 : 0;
}