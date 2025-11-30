const win32 = @import("win32");
const w = win32.everything;

const Modes = enum {
    Hidden,
    Grid,
    RowChosen,
    ColChosen,
};
pub fn letterToVK(s: c_char) w.VIRTUAL_KEY {
    return switch (s) {
        '-' => w.VK_RETURN,
        ';' => w.VK_SEMICOLON,
        ',' => w.VK_OEM_COMMA,
        '.' => w.VK_OEM_PERIOD,
        _ => s - 'a' + w.VK_A,
    };
}

pub const horizonthal = "qwfpbarstgzxcdvjluykneiomh"; // "qwfpbarstgzxcdv";
pub const vertical = "qwfpbarstgzxcdvjluykneiomh"; //"jluy;kneiom,.-";

pub const labels = init: {
    var result: [vertical.len][horizonthal.len][3:0]u16 = undefined;
    for (vertical, 0..) |first, i| {
        for (horizonthal, 0..) |second, j| {
            result[i][j] = .{ @intCast(first + 'A' - 'a'), @intCast(' '), @intCast(second + 'A' - 'a') };
        }
    }
    break :init result;
};

pub const pos = extern struct {
    x: i32,
    y: i32,
};

pub var axisSize = pos{ .x = 0, .y = 0 };
pub var labelSize = pos{ .x = 0, .y = 0 };
pub var screenSize = pos{ .x = 0, .y = 0 };

var g_hFont: ?w.HFONT = undefined;

pub fn destroy() void {
    if (g_hFont) |h| _ = w.DeleteObject(h);
}

pub fn drawLabels(hwnd: ?w.HWND) void {
    const hInstance = w.GetModuleHandleW(null);

    axisSize = pos{ .x = horizonthal.len, .y = vertical.len };
    const monitor = w.MonitorFromWindow(hwnd, w.MONITOR_DEFAULTTONEAREST);
    var info = w.MONITORINFO{ .cbSize = @sizeOf(w.MONITORINFO), .dwFlags = 0, .rcMonitor = w.RECT{ .left = 0, .bottom = 0, .right = 0, .top = 0 }, .rcWork = w.RECT{ .bottom = 0, .left = 0, .right = 0, .top = 0 } };

    _ = w.GetMonitorInfoW(monitor, &info);

    screenSize = pos{ .x = info.rcMonitor.right - info.rcMonitor.left, .y = info.rcMonitor.bottom - info.rcMonitor.top };
    labelSize = pos{ .x = @divTrunc(screenSize.x, axisSize.x), .y = @divTrunc(screenSize.y, axisSize.y) };

    g_hFont = w.CreateFontW(
        20,
        0,
        0,
        0,
        w.FW_MEDIUM,
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

    for (0..horizonthal.len) |i| {
        for (0..vertical.len) |j| {
            const x: i32 = @divTrunc((@as(i32, @intCast(i)) * screenSize.x), axisSize.x);
            const y: i32 = @divTrunc((@as(i32, @intCast(j)) * screenSize.y), axisSize.y);
            const newLabel = w.CreateWindowExW(w.WINDOW_EX_STYLE{}, w.L("STATIC"), &labels[i][j], w.WINDOW_STYLE{
                .VISIBLE = 1,
                .CHILD = 1,
                .ACTIVECAPTION = 1, // .CENTER
            }, x, y, labelSize.x, labelSize.y, hwnd, null, hInstance, null);
            _ = w.SendMessageW(newLabel, w.WM_SETFONT, @intCast(@intFromPtr(g_hFont)), 1);
        }
    }
}

pub const boardlineLen = 10;
pub const boardHeight = 3;
pub const boardChars = "qwfpbjluy;arstgkneiozxcdvmh,.-";

//    private bool rightMouse = false;
