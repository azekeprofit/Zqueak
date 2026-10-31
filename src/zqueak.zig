fn wndProc(
    hwnd: w.HWND,
    msg: u32,
    wParam: w.WPARAM,
    lParam: w.LPARAM,
) callconv(.winapi) w.LRESULT {
    return switch (msg) {
        w.WM_DESTROY => {
            if (d.g_hFont) |h| _ = w.DeleteObject(h);
            if (m.kbHookHandle) |h| _ = w.UnhookWindowsHookEx(h);
            if (m.mouseHookHandle) |h| _ = w.UnhookWindowsHookEx(h);

            w.PostQuitMessage(0);
            return 0;
        },
         w.WM_CTLCOLORSTATIC => {
             const hwndStatic = @as(w.HWND, @ptrFromInt(@as(usize,@bitCast(lParam))));
             if (m.mode == .ColChosen and w.GetDlgCtrlID(hwndStatic) == (100+m.cursor.x)) {
                 const hdc=@as(w.HDC, @ptrFromInt(wParam));
                 _ = w.SetBkColor(hdc, w.COLORREF.rgb(50,200,50));
                 return @intCast(@intFromPtr(tBrush));
             }
             return 0;
        },
        w.WM_MOUSEACTIVATE => w.MA_NOACTIVATE,
        w.WM_CREATE => {
            s.initScreen(hwnd);
            d.drawLabels(hwnd);
            return 0;
        },
        else => w.DefWindowProcW(hwnd, msg, wParam, lParam),
    };
}

pub fn main() !void {
    tBrush = w.CreateSolidBrush(transparent);

    const hInstance = w.GetModuleHandleW(null);

    const wc = w.WNDCLASSW{
        .style = .{ .VREDRAW = 1, .HREDRAW = 1 },
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
        .{ .LAYERED = 1, .TOPMOST = 1 },
        WINDOW_CLASS_NAME,
        w.L("Zqueak"),
        .{},
        12000,
        12000,
        100,
        100,
        null,
        null,
        hInstance,
        null,
    ) orelse @panic("Couldn't create window");

    _ = w.SetLayeredWindowAttributes(m.mainWindow, w.COLORREF.black, 20, w.LWA_ALPHA);
    _ = w.SetWindowLongW(m.mainWindow, w.GWL_STYLE, @bitCast(w.WS_POPUP));

    // _ = w.ShowWindow(hwnd, w.SW_SHOWMAXIMIZED);

    m.kbHookHandle = w.SetWindowsHookExW(w.WH_KEYBOARD_LL, m.keyHandler, hInstance, 0);
    if (m.kbHookHandle == null) {
        @panic("couldn't register keyboard hook");
    }

    m.mouseHookHandle = w.SetWindowsHookExW(w.WH_MOUSE_LL, m.mouseHandler, hInstance, 0);
    if (m.mouseHookHandle == null) {
        @panic("couldn't register mouse hook");
    }

    var msg: w.MSG = undefined;
    while (w.GetMessageW(&msg, null, 0, 0) > 0) {
        _ = w.TranslateMessage(&msg);
        _ = w.DispatchMessageW(&msg);
    }
}

const std = @import("std");
const win32 = @import("win32");
const w = win32.everything;
const m = @import("machine.zig");
const d = @import("drawLabels.zig");
const s = @import("screen.zig");

pub const transparent = w.COLORREF.rgb(180, 80, 80);
var tBrush: ?w.HBRUSH = undefined;
const WINDOW_CLASS_NAME = w.L("ZigBlankWindow");
