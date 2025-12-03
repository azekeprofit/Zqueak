pub fn initScreen(hwnd: w.HWND) void {
    axisSize = .{ .x = m.horizonthal.len, .y = m.vertical.len };
    const monitor = w.MonitorFromWindow(hwnd, w.MONITOR_DEFAULTTONEAREST);
    var info = w.MONITORINFO{ .cbSize = @sizeOf(w.MONITORINFO), .dwFlags = 0, .rcMonitor = .{ .left = 0, .bottom = 0, .right = 0, .top = 0 }, .rcWork = .{ .bottom = 0, .left = 0, .right = 0, .top = 0 } };

    _ = w.GetMonitorInfoW(monitor, &info);

    screenSize = .{ .x = info.rcMonitor.right - info.rcMonitor.left, .y = info.rcMonitor.bottom - info.rcMonitor.top };
}

pub var screenSize = pos{ .x = 0, .y = 0 };
pub var axisSize = pos{ .x = 0, .y = 0 };

const win32 = @import("win32");
const w = win32.everything;
pub const pos = struct {
    x: i32,
    y: i32,
};
const m = @import("machine.zig");
