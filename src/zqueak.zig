const std = @import("std");
const win32 = @import("win32");
const w = win32.everything;

fn packRgb(r: u8, g: u8, b: u8) u32 {
    return (@as(u32, b) << 16) |
        (@as(u32, g) << 8) |
        (@as(u32, r));
}

const transparent = packRgb(0, 50, 0);

const WINDOW_CLASS_NAME = w.L("ZigBlankWindow");

fn wndProc(
    hwnd: w.HWND,
    msg: u32,
    wParam: w.WPARAM,
    lParam: w.LPARAM,
) callconv(.winapi) w.LRESULT {
    return switch (msg) {
        w.WM_DESTROY => {
            w.PostQuitMessage(0);
            return 0;
        },
        else => w.DefWindowProcW(hwnd, msg, wParam, lParam),
    };
}

pub fn main() !void {
    const hInstance = w.GetModuleHandleW(null);

    const wc = w.WNDCLASSW{
        .style = w.WNDCLASS_STYLES{ .VREDRAW = 1, .HREDRAW = 1 },
        .lpfnWndProc = wndProc,
        .hInstance = hInstance,
        .hCursor = w.LoadCursorW(null, w.IDC_CROSS),
        .hbrBackground = w.CreateSolidBrush(transparent),
        .lpszClassName = WINDOW_CLASS_NAME,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hIcon = null,
        .lpszMenuName = null,
    };

    if (w.RegisterClassW(&wc) == 0) return error.RegisterClassFailed;

    const hwnd = w.CreateWindowExW(
        w.WINDOW_EX_STYLE{ .LAYERED = 1 },
        WINDOW_CLASS_NAME,
        w.L("Blank Zig Window"),
        w.WINDOW_STYLE{
            .VISIBLE = 0,
            .TABSTOP = 0,
            .GROUP = 0,
            .THICKFRAME = 0,
            .SYSMENU = 0,
            .DLGFRAME = 1,
            .BORDER = 1,
        },
        w.CW_USEDEFAULT,
        w.CW_USEDEFAULT,
        800,
        600,
        null,
        null,
        hInstance,
        null,
    ) orelse return error.CreateWindowFailed;

    _ = w.SetLayeredWindowAttributes(hwnd, transparent, 0, w.LWA_COLORKEY);

    _ = w.SetWindowLongW(hwnd, w.GWL_STYLE, @bitCast(w.WS_POPUP));

    _ = w.ShowWindow(hwnd, w.SW_SHOWMAXIMIZED);

    var msg: w.MSG = undefined;
    while (w.GetMessageW(&msg, null, 0, 0) > 0) {
        _ = w.TranslateMessage(&msg);
        _ = w.DispatchMessageW(&msg);
    }
}
