const std = @import("std");
const builtin = @import("builtin");

// Re-export all public types
pub const code_compressor = @import("code_compressor.zig");
pub const content_detector = @import("content_detector.zig");
pub const content_router = @import("content_router.zig");
pub const adaptive_sizer = @import("adaptive_sizer.zig");
pub const smart_crusher = @import("smart_crusher/main.zig");
pub const log_compressor = @import("log_compressor.zig");
pub const search_compressor = @import("search_compressor.zig");
pub const diff_compressor = @import("diff_compressor.zig");
pub const ccr = @import("ccr/main.zig");

pub const util = struct {
    pub const hash = @import("util/hash.zig");
    pub const math = @import("util/math.zig");
    pub const token_counter = @import("util/token_counter.zig");
};

pub const CompressConfig = @import("main.zig").CompressConfig;
pub const CompressResult = @import("main.zig").CompressResult;
pub const CompressionError = @import("main.zig").CompressionError;
pub const ContentType = @import("content_detector.zig").ContentType;
pub const DetectionResult = @import("content_detector.zig").DetectionResult;

pub const compress = @import("main.zig").compress;

test "all modules compile" {
    _ = @import("content_detector.zig");
    _ = @import("content_router.zig");
    _ = @import("adaptive_sizer.zig");
    _ = @import("smart_crusher/main.zig");
    _ = @import("log_compressor.zig");
    _ = @import("search_compressor.zig");
    _ = @import("diff_compressor.zig");
    _ = @import("ccr/main.zig");
    _ = @import("util/hash.zig");
    _ = @import("util/math.zig");
    _ = @import("util/token_counter.zig");
}