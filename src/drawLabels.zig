pub var axisSize = pos{ .x = 0, .y = 0 };
pub var labelSize = pos{ .x = 0, .y = 0 };
pub var screenSize = pos{ .x = 0, .y = 0 };

var label: [3:0]u16 = undefined;
pub fn drawLabels(hwnd: ?w.HWND) void {
    const hInstance = w.GetModuleHandleW(null);

    axisSize = .{ .x = m.horizonthal.len, .y = m.vertical.len };
    const monitor = w.MonitorFromWindow(hwnd, w.MONITOR_DEFAULTTONEAREST);
    var info = w.MONITORINFO{ .cbSize = @sizeOf(w.MONITORINFO), .dwFlags = 0, .rcMonitor = .{ .left = 0, .bottom = 0, .right = 0, .top = 0 }, .rcWork = .{ .bottom = 0, .left = 0, .right = 0, .top = 0 } };

    _ = w.GetMonitorInfoW(monitor, &info);

    screenSize = .{ .x = info.rcMonitor.right - info.rcMonitor.left, .y = info.rcMonitor.bottom - info.rcMonitor.top };
    labelSize = .{ .x = @divTrunc(screenSize.x, axisSize.x), .y = @divTrunc(screenSize.y, axisSize.y) };

    g_hFont = w.CreateFontW(
        20,
        0,
        0,
        0,
        w.FW_DEMIBOLD,
        0,
        0,
        0,
        w.DEFAULT_CHARSET,
        w.OUT_DEFAULT_PRECIS,
        w.CLIP_DEFAULT_PRECIS,
        w.CLEARTYPE_QUALITY,
        w.FF_DONTCARE,
        w.L("Segoe UI"),
    );

    label[1] = @intCast(' ');
    for (0..m.horizonthal.len) |i| {
        label[2] = upper(m.horizonthal[i]);
        for (0..m.vertical.len) |j| {
            label[0] = upper(m.vertical[j]);
            const x: i32 = @divTrunc((@as(i32, @intCast(i)) * screenSize.x), axisSize.x);
            const y: i32 = @divTrunc((@as(i32, @intCast(j)) * screenSize.y), axisSize.y);
            const newLabel = w.CreateWindowExW(.{}, w.L("STATIC"), &label, .{
                .VISIBLE = 1,
                .CHILD = 1,
                .BORDER = 1,
                .ACTIVECAPTION = 1, // .CENTER
            }, x, y, labelSize.x, labelSize.y, hwnd, null, hInstance, null) orelse @panic("Failed creating label");
            _ = w.SendMessageW(newLabel, w.WM_SETFONT, @intCast(@intFromPtr(g_hFont)), 1);

            // _ = w.SetTextColor(w.GetDC(newLabel), z.packRgb(255, 255, 255)); // white text
            // _ = w.SetBkColor(w.GetDC(newLabel), z.packRgb(180, 80, 80)); // red background
            // _ = w.SetBkMode(w.GetDC(newLabel), w.TRANSPARENT);
        }
    }
}

const win32 = @import("win32");
const w = win32.everything;
const m = @import("machine.zig");

pub var g_hFont: ?w.HFONT = undefined;
pub const pos = struct {
    x: i32,
    y: i32,
};

fn upper(char: u8) u16 {
    return switch (char) {
        'a'...'z' => @as(u16, @intCast(char + 'A' - 'a')),
        else => @intCast(char),
    };
}
