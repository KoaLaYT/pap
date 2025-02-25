const std = @import("std");
const radian = std.math.degreesToRadians;

const EarchRadius: f64 = 6371.0;

const Pair = struct {
    x0: f64,
    y0: f64,
    x1: f64,
    y1: f64,

    fn haversineDistance(self: @This()) f64 {
        const dy: f64 = radian(self.y1 - self.y0);
        const dx: f64 = radian(self.x1 - self.x0);
        const y0: f64 = radian(self.y0);
        const y1: f64 = radian(self.y1);

        const sin_dy: f64 = @sin(dy / 2);
        const sin_dx: f64 = @sin(dx / 2);
        const root_term: f64 = sin_dy * sin_dy + @cos(y0) * @cos(y1) * sin_dx * sin_dx;
        return 2.0 * EarchRadius * std.math.asin(@sqrt(root_term));
    }
};

const Data = struct { pairs: []Pair };

fn elapsedSeconds(t1: std.time.Instant, t2: std.time.Instant) f64 {
    const elapsed: f64 = @floatFromInt(t1.since(t2));
    const base: f64 = std.time.ns_per_s;
    return elapsed / base;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const f = try std.fs.cwd().openFile("data.json", .{});
    defer f.close();

    const start_time = try std.time.Instant.now();

    var buffered = std.io.bufferedReader(f.reader());
    var r = std.json.reader(allocator, buffered.reader());
    defer r.deinit();
    const parsed = try std.json.parseFromTokenSource(
        Data,
        allocator,
        &r,
        .{ .allocate = .alloc_if_needed },
    );
    defer parsed.deinit();
    const mid_time = try std.time.Instant.now();

    var sum: f64 = 0.0;
    var count: usize = 0;
    for (parsed.value.pairs) |pair| {
        sum += pair.haversineDistance();
        count += 1;
    }
    const avg = sum / @as(f64, @floatFromInt(count));
    const end_time = try std.time.Instant.now();

    std.debug.print("Result: {d:.6}\n", .{avg});
    std.debug.print("Input = {d:.6} seconds\n", .{elapsedSeconds(mid_time, start_time)});
    std.debug.print("Math = {d:.6} seconds\n", .{elapsedSeconds(end_time, mid_time)});
    std.debug.print("Total = {d:.6} seconds\n", .{elapsedSeconds(end_time, start_time)});
    std.debug.print("Throughput = {d:.6} haversines/second\n", .{@as(f64, @floatFromInt(count)) / (elapsedSeconds(end_time, start_time))});
}
