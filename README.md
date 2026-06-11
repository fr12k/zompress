# zompress

Content-aware compression for AI agent tool outputs. 60–95% token
reduction on JSON, logs, search results, diffs, and source code.

## Why

LLM context windows fill up fast when agents run tools. A `kubectl get
pods -o json` can be 200 KB. A `git diff` across 50 files can be 100
KB. A pytest run with 10K lines of output is 500 KB.

Most of those tokens are **noise** — identical rows, repeated log
lines, unchanged context, indentation. The LLM only needs the
structure, the errors, and the boundaries.

Zompress analyzes the **structure** of tool output and keeps only what
matters — errors, anomalies, diverse samples, first/last items.
Original content is stored via CCR (Compress-Cache-Retrieve) so the
LLM can retrieve anything that was dropped.

## Quick Start

```zig
const zompress = @import("zompress");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const json = try std.fs.cwd().readFileAlloc(arena.allocator(), "pods.json", 10 * 1024 * 1024);

    const result = try zompress.compress(arena.allocator(), json, .{
        .smart_crusher_enabled = true,
        .log_compressor_enabled = true,
        .search_compressor_enabled = true,
        .diff_compressor_enabled = true,
    });

    std.debug.print("Compressed from {} to {} bytes ({}%)\n", .{
        result.tokens_before * 4,
        result.tokens_after * 4,
        @as(u64, @intFromFloat(result.compression_ratio * 100)),
    });
    std.debug.print("{s}\n", .{result.compressed});
}
```

### CLI

```bash
$ echo '[{"msg":"ok"},{"msg":"error: timeout"}]' | zompress
# → [{"msg":"ok"},{"msg":"error: timeout"}]
#   (compresses arrays with >5 items)
```

## Compression Modules

| Module | Input | Strategy | Typical Reduction |
|--------|-------|----------|-------------------|
| **SmartCrusher** | JSON arrays `[{...}, ...]` | Classifies element type, keeps first+last+error items, samples middle | **60–90%** |
| **LogCompressor** | Build/test output (pytest, cargo, npm) | Detects log format, preserves errors + stack traces + summaries | **80–95%** |
| **SearchCompressor** | Grep/ripgrep results | Groups by file, keeps first/last per file, caps matches | **70–85%** |
| **DiffCompressor** | Git diffs | Parses unified diff, trims context lines, caps hunks | **50–70%** |
| **CodeCompressor** | Zig source code | Uses `std.zig.Ast` — keeps signatures + errors + returns, drops body | **60–80%** |
| **ContentDetector** | Any text | Heuristic detection (no regex), routes to correct compressor | — |

### Auto-Detection

Call `compress()` — it detects the content type and dispatches:

```
[{"a":1},{"a":2}]            → SmartCrusher (JSON array)
diff --git a/x b/x           → DiffCompressor
ERROR: something failed      → LogCompressor
src/main.zig:42:fn process() → SearchCompressor
pub fn main() !void {…}      → CodeCompressor (Zig source)
Hello world                  → Plain text (passthrough)
```

## Compress-Cache-Retrieve (CCR)

Compression is **lossy** by design. CCR makes it **reversible**:

```zig
var store = zompress.ccr.CcrStore.init(allocator);
defer store.deinit();

// Store original, get a hash key
const key = try store.store(large_json); // "a1b2c3d4e5f6..."

// The compressed output includes a marker:
// "<<ccr:a1b2c3d4e5f6 42_rows_offloaded>>"

// The LLM can retrieve the original when needed:
const original = store.retrieve(key).?;
```

## Adaptive Sizer (Kneedle)

Determines the optimal number of items to keep using the Kneedle
algorithm — finds the "elbow" in the importance curve where marginal
value drops off:

```zig
const k = adaptive_sizer.computeOptimalK(items, 1.0, 3, 15);
// Returns the knee point: how many items to keep
```

## Content Detection (no regex)

All pattern matching is done with manual byte scanners — no regex
library needed:

```
"["       → try JSON parse
"{"       → try JSON parse
"<"       → check HTML/XML tags
"diff --git" → git diff
"file:42:content" → search results
"ERROR" / "Traceback" → build output
"import" / "pub fn" → source code
3+ commas → CSV
```

## Build & Test

```bash
# Build library + CLI
zig build

# Run all 61 tests
zig build test

# Build optimized
zig build -Doptimize=ReleaseFast
```

## Integration with AI Agents

Zompress is designed to sit between tool execution and the LLM context:

1. Agent runs a tool → gets output
2. Output passes through `zompress.compress()` → compressed result
3. Original goes into CCR store
4. LLM sees only the compressed version
5. If LLM needs full details, it retrieves via CCR key

## License

MIT