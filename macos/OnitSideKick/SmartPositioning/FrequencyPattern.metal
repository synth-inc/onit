//
//  FrequencyPattern.metal
//  Onit
//
//  GPU-accelerated frequency pattern detection (text oscillation)
//

#include <metal_stdlib>
using namespace metal;

struct FrequencyParams {
    uint width;
    uint height;
    uint tileSize;
    uint samplingStride;     // Horizontal sampling stride (e.g., 2)
    uint lineStride;         // Vertical line stride (e.g., 4 = sample every 4th row)
    float changeThreshold;   // Minimum brightness change to count (e.g., 40.0)
    uint tilesX;
    uint tilesY;
};

/// Compute frequency pattern complexity for each tile by detecting brightness oscillations
/// Scans horizontally and counts frequent brightness changes (text creates ABABAB pattern)
kernel void frequency_pattern_per_tile(
    texture2d<half, access::read> texture         [[texture(0)]],
    device atomic_uint* changeCount               [[buffer(0)]],  // Count of brightness changes per tile
    device atomic_uint* totalComparisons          [[buffer(1)]],  // Total comparisons per tile
    constant FrequencyParams& p                   [[buffer(2)]],
    uint2 gid                                     [[thread_position_in_grid]])
{
    // Each thread processes one horizontal scan line
    if (gid.x >= p.width || gid.y >= p.height) return;

    // Only process at line stride intervals
    if ((gid.y % p.lineStride) != 0) return;

    // Only start at x=0 (we'll scan the entire row)
    if (gid.x != 0) return;

    // Calculate which tile this line belongs to
    uint tileY = gid.y / p.tileSize;
    if (tileY >= p.tilesY) return;

    // Track changes across the entire row, accumulating per tile
    float previousGray = -1.0f;
    float previousChange = 0.0f;

    for (uint x = 0; x < p.width; x += p.samplingStride) {
        uint2 pos = uint2(x, gid.y);
        half4 pixel = texture.read(pos);

        // Convert to grayscale
        float gray = 0.299f * float(pixel.r) + 0.587f * float(pixel.g) + 0.114f * float(pixel.b);
        // Scale to 0-255 range
        gray *= 255.0f;

        // Determine which tile this pixel belongs to
        uint tileX = x / p.tileSize;
        if (tileX >= p.tilesX) continue;
        uint tileIdx = tileY * p.tilesX + tileX;

        if (previousGray >= 0.0f) {
            float change = fabs(gray - previousGray);

            // Count this comparison
            atomic_fetch_add_explicit(&totalComparisons[tileIdx], 1u, memory_order_relaxed);

            if (change > p.changeThreshold) {
                atomic_fetch_add_explicit(&changeCount[tileIdx], 1u, memory_order_relaxed);

                // BONUS: Detect oscillation pattern (ABABAB - very text-like)
                // If previous change was also significant, this is oscillating
                if (previousChange > p.changeThreshold) {
                    atomic_fetch_add_explicit(&changeCount[tileIdx], 1u, memory_order_relaxed);
                }
            }

            previousChange = change;
        }

        previousGray = gray;
    }
}

/// Compute frequency pattern complexity for each pixel using a local window
/// Each thread processes one pixel, computing complexity within a windowSize x windowSize region around it
kernel void frequency_pattern_per_pixel(
    texture2d<half, access::read> texture         [[texture(0)]],
    device float* complexityOutput                [[buffer(0)]],  // Per-pixel complexity (0-100)
    constant FrequencyParams& p                   [[buffer(2)]],
    uint2 gid                                     [[thread_position_in_grid]])
{
    if (gid.x >= p.width || gid.y >= p.height) return;

    uint pixelIdx = gid.y * p.width + gid.x;

    // Define local window around this pixel (tileSize is used as windowSize)
    uint halfWindow = p.tileSize / 2;
    uint windowStartX = (gid.x >= halfWindow) ? gid.x - halfWindow : 0;
    uint windowEndX = min(gid.x + halfWindow, p.width - 1);
    uint windowStartY = (gid.y >= halfWindow) ? gid.y - halfWindow : 0;
    uint windowEndY = min(gid.y + halfWindow, p.height - 1);

    // Compute complexity within this local window
    uint changeCount = 0;
    uint totalComparisons = 0;

    // Scan horizontally within window (similar to tile-based approach)
    for (uint y = windowStartY; y <= windowEndY; y += p.lineStride) {
        float previousGray = -1.0f;
        float previousChange = 0.0f;

        for (uint x = windowStartX; x <= windowEndX; x += p.samplingStride) {
            uint2 pos = uint2(x, y);
            half4 pixel = texture.read(pos);

            // Convert to grayscale
            float gray = 0.299f * float(pixel.r) + 0.587f * float(pixel.g) + 0.114f * float(pixel.b);
            // Scale to 0-255 range
            gray *= 255.0f;

            if (previousGray >= 0.0f) {
                float change = fabs(gray - previousGray);
                totalComparisons++;

                if (change > p.changeThreshold) {
                    changeCount++;

                    // Detect oscillation pattern (ABABAB - very text-like)
                    // If previous change was also significant, this is oscillating
                    if (previousChange > p.changeThreshold) {
                        changeCount++;
                    }
                }

                previousChange = change;
            }

            previousGray = gray;
        }
    }

    // Calculate complexity percentage for this pixel
    float complexity = 0.0f;
    if (totalComparisons > 0) {
        complexity = (float(changeCount) / float(totalComparisons)) * 100.0f;
    }

    complexityOutput[pixelIdx] = complexity;
}

struct RectangleSearchParams {
    uint width;
    uint height;
    uint targetWidth;
    uint targetHeight;
};

/// Builds horizontal prefix sum (row-wise scan)
/// Each element (x,y) contains the sum of all complexities from (0,y) to (x,y)
/// Optionally adds bias values if biasBuffer is provided
kernel void build_prefix_sum_horizontal(
    device float* complexityBuffer [[buffer(0)]],  // Input: per-pixel complexity
    device float* prefixSumBuffer [[buffer(1)]],   // Output: horizontal prefix sum
    constant uint2& dimensions [[buffer(2)]],      // width, height
    device float* biasBuffer [[buffer(3)]],        // Optional: per-pixel bias (can be null)
    uint2 gid [[thread_position_in_grid]])
{
    uint width = dimensions.x;
    uint height = dimensions.y;

    // Each thread processes one row
    if (gid.y >= height) return;

    uint rowStart = gid.y * width;
    float runningSum = 0.0;

    for (uint x = 0; x < width; x++) {
        uint idx = rowStart + x;
        float value = complexityBuffer[idx];

        // Add bias if provided
        if (biasBuffer != nullptr) {
            value += biasBuffer[idx];
        }

        runningSum += value;
        prefixSumBuffer[idx] = runningSum;
    }
}

/// Builds full 2D prefix sum by adding vertical sums to horizontal prefix sum
/// Each element (x,y) contains the sum of all complexities from (0,0) to (x,y)
kernel void build_prefix_sum_vertical(
    device float* prefixSumBuffer [[buffer(0)]],   // Input/Output: horizontal prefix sum -> full 2D prefix sum
    constant uint2& dimensions [[buffer(1)]],      // width, height
    uint2 gid [[thread_position_in_grid]])
{
    uint width = dimensions.x;
    uint height = dimensions.y;

    // Each thread processes one column
    if (gid.x >= width) return;

    float runningSum = 0.0;

    for (uint y = 0; y < height; y++) {
        uint idx = y * width + gid.x;
        runningSum += prefixSumBuffer[idx];
        prefixSumBuffer[idx] = runningSum;
    }
}

/// Finds the minimum complexity rectangle by computing rectangle sums using prefix sum
/// Each thread computes the sum for one possible rectangle position
kernel void find_minimum_rectangle(
    device float* prefixSumBuffer [[buffer(0)]],
    device atomic_float* minSum [[buffer(1)]],
    device atomic_uint* minPosition [[buffer(2)]],  // Packed as (y << 16) | x
    constant RectangleSearchParams& params [[buffer(3)]],
    uint2 gid [[thread_position_in_grid]])
{
    uint width = params.width;
    uint height = params.height;
    uint targetWidth = params.targetWidth;
    uint targetHeight = params.targetHeight;

    // Calculate valid positions for the target rectangle
    uint maxX = (width >= targetWidth) ? (width - targetWidth) : 0;
    uint maxY = (height >= targetHeight) ? (height - targetHeight) : 0;

    // Use thread position directly as rectangle position
    // Early exit if this thread is beyond valid positions
    if (gid.x > maxX || gid.y > maxY) return;

    uint rectX = gid.x;
    uint rectY = gid.y;

    // Calculate rectangle bounds
    uint r1 = rectY;
    uint c1 = rectX;
    uint r2 = rectY + targetHeight - 1;
    uint c2 = rectX + targetWidth - 1;

    // Clamp to bounds
    r2 = min(r2, height - 1);
    c2 = min(c2, width - 1);

    // Compute rectangle sum using prefix sum (O(1))
    // Formula: sum = prefix[r2][c2] - prefix[r1-1][c2] - prefix[r2][c1-1] + prefix[r1-1][c1-1]
    uint idxBottomRight = r2 * width + c2;
    float sum = prefixSumBuffer[idxBottomRight];

    if (c1 > 0) {
        uint idxBottomLeft = r2 * width + (c1 - 1);
        sum -= prefixSumBuffer[idxBottomLeft];
    }
    if (r1 > 0) {
        uint idxTopRight = (r1 - 1) * width + c2;
        sum -= prefixSumBuffer[idxTopRight];
    }
    if (c1 > 0 && r1 > 0) {
        uint idxTopLeft = (r1 - 1) * width + (c1 - 1);
        sum += prefixSumBuffer[idxTopLeft];
    }

    // Update minimum using atomic operations
    // Note: There's a potential race between updating minSum and minPosition.
    // To minimize this, we re-check after storing the position.
    float currentMin = atomic_load_explicit(minSum, memory_order_relaxed);
    if (sum < currentMin) {
        // Try to update minimum atomically
        bool updated = false;
        while (!updated) {
            float expected = currentMin;
            updated = atomic_compare_exchange_weak_explicit(
                minSum,
                &expected,
                sum,
                memory_order_relaxed,
                memory_order_relaxed
            );
            if (!updated) {
                currentMin = expected;
                if (sum >= currentMin) break; // Someone else found a better minimum
            } else {
                // Successfully updated minimum, also update position
                uint packedPos = (rectY << 16) | rectX;
                atomic_store_explicit(minPosition, packedPos, memory_order_relaxed);

                // Re-verify our sum is still the minimum (reduce race condition impact)
                // If someone else updated with a better value, don't worry - their position will be stored
                float verifyMin = atomic_load_explicit(minSum, memory_order_relaxed);
                if (verifyMin < sum) {
                    // Someone else found a better minimum, they'll update position
                    break;
                }
            }
        }
    }
}
