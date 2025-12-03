var label: [3:0]u16 = undefined;
pub fn drawLabels(hwnd: ?w.HWND) void {
    const hInstance = w.GetModuleHandleW(null);
    labelSize = .{ .x = @divTrunc(s.screenSize.x, s.axisSize.x), .y = @divTrunc(s.screenSize.y, s.axisSize.y) };

    g_hFont = w.CreateFontW(
        20,
        0,
        0,
        0,
        w.FW_BOLD,
        0,
        0,
        0,
        w.DEFAULT_CHARSET,
        w.OUT_DEFAULT_PRECIS,
        w.CLIP_DEFAULT_PRECIS,
        w.CLEARTYPE_QUALITY,
        w.FF_DONTCARE,
        w.L("Proforma"),
    );

    label[1] = @intCast(' ');
    for (0.., m.horizonthal) |i, hLetter| {
        label[2] = hLetter;
        for (0.., m.vertical) |j, vLetter| {
            label[0] = vLetter;
            const x: i32 = @divTrunc((@as(i32, @intCast(i)) * s.screenSize.x), s.axisSize.x);
            const y: i32 = @divTrunc((@as(i32, @intCast(j)) * s.screenSize.y), s.axisSize.y);
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

pub var labelSize = pos{ .x = 0, .y = 0 };

pub var g_hFont: ?w.HFONT = undefined;

const win32 = @import("win32");
const w = win32.everything;
const m = @import("machine.zig");
const s = @import("screen.zig");
const pos = s.pos;
