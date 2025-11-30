const std = @import("std");
const win32 = @import("win32");
const w = win32.everything;
const m = @import("machine.zig");

extern "gdi32" fn SetBkColor(
    hdc: w.WPARAM,
    color: u32,
) callconv(.winapi) u32;

extern "gdi32" fn CreateSolidBrush(
    color: u32,
) callconv(.winapi) w.LRESULT;

fn packRgb(r: u8, g: u8, b: u8) u32 {
    return (@as(u32, b) << 16) |
        (@as(u32, g) << 8) |
        (@as(u32, r));
}
const transparent = packRgb(0, 50, 0);
var tBrush: ?w.HBRUSH = undefined;
const WINDOW_CLASS_NAME = w.L("ZigBlankWindow");

fn wndProc(
    hwnd: w.HWND,
    msg: u32,
    wParam: w.WPARAM,
    lParam: w.LPARAM,
) callconv(.winapi) w.LRESULT {
    return switch (msg) {
        w.WM_DESTROY => {
            m.destroy();
            w.PostQuitMessage(0);
            return 0;
        },
        w.WM_CTLCOLORSTATIC => {
            if (w.IsWindow(hwnd) != 0) {
                _ = w.SetBkColor(@ptrFromInt(wParam), transparent);
                return @intCast(@intFromPtr(w.GetStockObject(w.NULL_BRUSH)));
            }
            return 0;
        },
        w.WM_MOUSEACTIVATE => w.MA_NOACTIVATE,
        w.WM_CREATE => {
            m.drawLabels(hwnd);
            return 0;
        },
        else => w.DefWindowProcW(hwnd, msg, wParam, lParam),
    };
}

pub fn main() !void {
    tBrush = w.CreateSolidBrush(transparent);

    const hInstance = w.GetModuleHandleW(null);

    const wc = w.WNDCLASSW{
        .style = w.WNDCLASS_STYLES{ .VREDRAW = 1, .HREDRAW = 1 },
        .lpfnWndProc = wndProc,
        .hInstance = hInstance,
        .hCursor = w.LoadCursorW(null, w.IDC_CROSS),
        .hbrBackground = tBrush,
        .lpszClassName = WINDOW_CLASS_NAME,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hIcon = null,
        .lpszMenuName = null,
    };

    if (w.RegisterClassW(&wc) == 0) return error.RegisterClassFailed;

    m.mainWindow = w.CreateWindowExW(
        w.WINDOW_EX_STYLE{ .LAYERED = 1, .TOPMOST = 1 },
        WINDOW_CLASS_NAME,
        w.L("Zqueak"),
        w.WINDOW_STYLE{
            .VISIBLE = 0,
            .TABSTOP = 0,
            .GROUP = 0,
            .THICKFRAME = 0,
            .SYSMENU = 0,
            .DLGFRAME = 0,
            .BORDER = 0,
        },
        12000,
        12000,
        100,
        100,
        null,
        null,
        hInstance,
        null,
    ) orelse return error.CreateWindowFailed;

    _ = w.SetLayeredWindowAttributes(m.mainWindow, transparent, 0, w.LWA_COLORKEY);
    _ = w.SetWindowLongW(m.mainWindow, w.GWL_STYLE, @bitCast(w.WS_POPUP));

    // _ = w.ShowWindow(hwnd, w.SW_SHOWMAXIMIZED);

    m.hookHandle = w.SetWindowsHookExW(w.WH_KEYBOARD_LL, m.keyHandler, hInstance, 0);
    if (m.hookHandle == null) {
        return;
    }

    var msg: w.MSG = undefined;
    while (w.GetMessageW(&msg, null, 0, 0) > 0) {
        _ = w.TranslateMessage(&msg);
        _ = w.DispatchMessageW(&msg);
    }
}
