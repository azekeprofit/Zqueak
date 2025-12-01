pub fn keyHandler(nCode: i32, wParam: w.WPARAM, lParam: w.LPARAM) callconv(.c) w.LRESULT {
    return blk: {
        if (nCode == w.HC_ACTION and wParam == w.WM_KEYDOWN) {
            const kbd: *w.KBDLLHOOKSTRUCT = @ptrFromInt(@as(usize, @intCast(lParam)));
            const vk: w.VIRTUAL_KEY = @enumFromInt(kbd.vkCode);

            if (vk == w.VK_F13 and mode == Modes.Hidden) {
                mode = Modes.Grid;
                rightMouse = false;
                _ = w.ShowWindow(mainWindow, w.SW_SHOWMAXIMIZED);
                break :blk 1;
            }

            if (vk == w.VK_F13 and mode == Modes.Grid) {
                destroy();
                w.PostQuitMessage(0);
                break :blk 1;
            }

            if (vk == w.VK_ESCAPE and mode != Modes.Hidden) {
                mode = Modes.Hidden;
                _ = w.ShowWindow(mainWindow, w.SW_HIDE);
                break :blk 1;
            }
            if (vk == w.VK_TAB and mode != Modes.Hidden) {
                rightMouse = !rightMouse;
                break :blk 1;
            }
            if (mode == Modes.ColChosen and vk == w.VK_SPACE) {
                _ = w.ShowWindow(mainWindow, w.SW_HIDE);
                mode = Modes.Hidden;
                click(CellCenter());
                break :blk 1;
            }

            if (mode == Modes.Grid) {
                for (vertical, 0..) |first, i| {
                    if (letterToVK(first) == vk) {
                        rightMouse = false;
                        mode = Modes.RowChosen;
                        cursor.y = @intCast(i);
                        break :blk 1;
                    }
                }
            }

            if (mode == Modes.RowChosen) {
                for (horizonthal, 0..) |second, j| {
                    if (letterToVK(second) == vk) {
                        mode = Modes.ColChosen;
                        cursor.x = @intCast(j);
                        placeCursor(CellCenter());
                        break :blk 1;
                    }
                }
            }
            if (mode == Modes.ColChosen) {
                for (board, 0..) |key, boardPos| {
                    if (letterToVK(key) == vk) {
                        mode = Modes.Hidden;
                        _ = w.ShowWindow(mainWindow, w.SW_HIDE);
                        click(SubgridPos(boardPos));
                        break :blk 1;
                    }
                }
            }
        }
        break :blk w.CallNextHookEx(hookHandle, nCode, wParam, lParam);
    };
}

pub const horizonthal = "qwfpbarstgzxcdvjluykneiomh"; // "qwfpbarstgzxcdv";
pub const vertical = "qwfpbarstgzxcdvjluykneiomh"; //"jluy;kneiom,.-";

pub const boardlineLen = 10;
pub const boardHeight = 3;
pub const board = "qwfpbjluy;arstgkneiozxcdvmh,.-";

fn placeCursor(p: pos) void {
    _ = w.SetCursorPos(p.x, p.y);
}

fn click(p: pos) void {
    placeCursor(p);
    w.mouse_event(if (rightMouse) w.MOUSEEVENTF_RIGHTDOWN else w.MOUSEEVENTF_LEFTDOWN, p.x, p.y, 0, 0);
    w.mouse_event(if (rightMouse) w.MOUSEEVENTF_RIGHTUP else w.MOUSEEVENTF_LEFTUP, p.x, p.y, 0, 0);
}

fn CellLeftUpCorner() pos {
    return pos{
        .x = @divTrunc(cursor.x * screenSize.x, axisSize.x),
        .y = @divTrunc(cursor.y * screenSize.y, axisSize.y),
    };
}

fn CellCenter() pos {
    var p = CellLeftUpCorner();
    p.x += @divTrunc(labelSize.x, 2);
    p.y += @divTrunc(labelSize.y, 2);
    return p;
}

fn SubgridPos(boardPos: usize) pos {
    const subRow = boardPos / boardlineLen;
    const subCol = boardPos % boardlineLen;

    var p = CellLeftUpCorner();

    p.x += @divTrunc((@as(i32, @intCast(subCol)) * labelSize.x), boardlineLen);
    p.y += @divTrunc((@as(i32, @intCast(subRow)) * labelSize.y), boardHeight);
    return p;
}

pub var axisSize = pos{ .x = 0, .y = 0 };
pub var labelSize = pos{ .x = 0, .y = 0 };
pub var screenSize = pos{ .x = 0, .y = 0 };
pub var cursor = pos{ .x = 0, .y = 0 };

var label: [3:0]u16 = undefined;

fn upper(char: u8) u16 {
    return switch (char) {
        'a'...'z' => @as(u16, @intCast(char + 'A' - 'a')),
        else => @intCast(char),
    };
}
pub fn destroy() void {
    if (g_hFont) |h| _ = w.DeleteObject(h);
    if (hookHandle) |h| _ = w.UnhookWindowsHookEx(h);
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
    for (0..horizonthal.len) |i| {
        label[2] = upper(horizonthal[i]);
        for (0..vertical.len) |j| {
            label[0] = upper(vertical[j]);
            const x: i32 = @divTrunc((@as(i32, @intCast(i)) * screenSize.x), axisSize.x);
            const y: i32 = @divTrunc((@as(i32, @intCast(j)) * screenSize.y), axisSize.y);
            const newLabel = w.CreateWindowExW(w.WINDOW_EX_STYLE{}, w.L("STATIC"), &label, w.WINDOW_STYLE{
                .VISIBLE = 1,
                .CHILD = 1,
                .BORDER = 1,
                .ACTIVECAPTION = 1, // .CENTER
            }, x, y, labelSize.x, labelSize.y, hwnd, null, hInstance, null);
            _ = w.SendMessageW(newLabel, w.WM_SETFONT, @intCast(@intFromPtr(g_hFont)), 1);
        }
    }
}

const win32 = @import("win32");
const w = win32.everything;

const Modes = enum {
    Hidden,
    Grid,
    RowChosen,
    ColChosen,
};

pub const pos = extern struct {
    x: i32,
    y: i32,
};

var mode: Modes = Modes.Hidden;
var rightMouse = false;

pub var mainWindow: ?w.HWND = undefined;
pub var hookHandle: ?w.HHOOK = undefined;
var g_hFont: ?w.HFONT = undefined;

pub fn letterToVK(s: u8) w.VIRTUAL_KEY {
    return switch (s) {
        '-' => w.VK_RETURN,
        ';' => w.VK_OEM_1,
        ',' => w.VK_OEM_COMMA,
        '.' => w.VK_OEM_PERIOD,
        'a' => w.VK_A,
        'b' => w.VK_B,
        'c' => w.VK_C,
        'd' => w.VK_D,
        'e' => w.VK_E,
        'f' => w.VK_F,
        'g' => w.VK_G,
        'h' => w.VK_H,
        'i' => w.VK_I,
        'j' => w.VK_J,
        'k' => w.VK_K,
        'l' => w.VK_L,
        'm' => w.VK_M,
        'n' => w.VK_N,
        'o' => w.VK_O,
        'p' => w.VK_P,
        'q' => w.VK_Q,
        'r' => w.VK_R,
        's' => w.VK_S,
        't' => w.VK_T,
        'u' => w.VK_U,
        'v' => w.VK_V,
        'w' => w.VK_W,
        'x' => w.VK_X,
        'y' => w.VK_Y,
        'z' => w.VK_Z,

        'A' => w.VK_A, // Note: uppercase letters also map to the same VK codes
        'B' => w.VK_B, // (Windows VK codes are not case-sensitive)
        'C' => w.VK_C,
        'D' => w.VK_D,
        'E' => w.VK_E,
        'F' => w.VK_F,
        'G' => w.VK_G,
        'H' => w.VK_H,
        'I' => w.VK_I,
        'J' => w.VK_J,
        'K' => w.VK_K,
        'L' => w.VK_L,
        'M' => w.VK_M,
        'N' => w.VK_N,
        'O' => w.VK_O,
        'P' => w.VK_P,
        'Q' => w.VK_Q,
        'R' => w.VK_R,
        'S' => w.VK_S,
        'T' => w.VK_T,
        'U' => w.VK_U,
        'V' => w.VK_V,
        'W' => w.VK_W,
        'X' => w.VK_X,
        'Y' => w.VK_Y,
        'Z' => w.VK_Z,
        else => @enumFromInt(s),
    };
}
