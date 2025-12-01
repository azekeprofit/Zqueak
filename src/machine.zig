pub const horizonthal = "abcdefghijklmnopqrstuvwxyz"; // "qwfpbarstgzxcdv";
pub const vertical = "abcdefghijklmnopqrstuvwxyz"; //"jluy;kneiom,.-";

pub const boardlineLen = 10;
pub const boardHeight = 3;
pub const board = "qwfpbjluy;arstgkneiozxcdvmh,.-";

pub fn keyHandler(nCode: i32, wParam: w.WPARAM, lParam: w.LPARAM) callconv(.c) w.LRESULT {
    return blk: {
        if (nCode == w.HC_ACTION and wParam == w.WM_KEYDOWN) {
            const kbd: *w.KBDLLHOOKSTRUCT = @ptrFromInt(@as(usize, @intCast(lParam)));
            const vk: w.VIRTUAL_KEY = @enumFromInt(kbd.vkCode);

            if (vk == w.VK_F13 and mode == .Hidden) {
                mode = .Grid;
                rightMouse = false;
                _ = w.ShowWindow(mainWindow, w.SW_SHOWMAXIMIZED);
                break :blk 1;
            }

            if (vk == w.VK_F13 and mode == .Grid) {
                w.PostQuitMessage(0);
                break :blk 1;
            }

            if (vk == w.VK_ESCAPE and mode != .Hidden) {
                mode = .Hidden;
                _ = w.ShowWindow(mainWindow, w.SW_HIDE);
                break :blk 1;
            }
            if (vk == w.VK_TAB and mode != .Hidden) {
                rightMouse = !rightMouse;
                break :blk 1;
            }
            if (mode == .ColChosen and vk == w.VK_SPACE) {
                _ = w.ShowWindow(mainWindow, w.SW_HIDE);
                mode = .Hidden;
                click(CellCenter());
                break :blk 1;
            }

            if (mode == .Grid) {
                for (vertical, 0..) |first, i| {
                    if (letterToVK(first) == vk) {
                        rightMouse = false;
                        mode = .RowChosen;
                        cursor.y = @intCast(i);
                        break :blk 1;
                    }
                }
            }

            if (mode == .RowChosen) {
                for (horizonthal, 0..) |second, j| {
                    if (letterToVK(second) == vk) {
                        mode = .ColChosen;
                        cursor.x = @intCast(j);
                        placeCursor(CellCenter());
                        break :blk 1;
                    }
                }
            }
            if (mode == .ColChosen) {
                for (board, 0..) |key, boardPos| {
                    if (letterToVK(key) == vk) {
                        mode = .Hidden;
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

fn placeCursor(p: pos) void {
    _ = w.SetCursorPos(p.x, p.y);
}

fn click(p: pos) void {
    placeCursor(p);
    w.mouse_event(if (rightMouse) w.MOUSEEVENTF_RIGHTDOWN else w.MOUSEEVENTF_LEFTDOWN, p.x, p.y, 0, 0);
    w.mouse_event(if (rightMouse) w.MOUSEEVENTF_RIGHTUP else w.MOUSEEVENTF_LEFTUP, p.x, p.y, 0, 0);
}

fn CellLeftUpCorner() pos {
    return .{
        .x = @divTrunc(cursor.x * d.screenSize.x, d.axisSize.x),
        .y = @divTrunc(cursor.y * d.screenSize.y, d.axisSize.y),
    };
}

fn CellCenter() pos {
    var p = CellLeftUpCorner();
    p.x += @divTrunc(d.labelSize.x, 2);
    p.y += @divTrunc(d.labelSize.y, 2);
    return p;
}

fn SubgridPos(boardPos: usize) pos {
    const subRow = boardPos / boardlineLen;
    const subCol = boardPos % boardlineLen;

    var p = CellLeftUpCorner();

    p.x += @divTrunc((@as(i32, @intCast(subCol)) * d.labelSize.x), boardlineLen);
    p.y += @divTrunc((@as(i32, @intCast(subRow)) * d.labelSize.y), boardHeight);
    return p;
}

pub var cursor = pos{ .x = 0, .y = 0 };

const win32 = @import("win32");
const w = win32.everything;

const Modes = enum {
    Hidden,
    Grid,
    RowChosen,
    ColChosen,
};

var mode: Modes = .Hidden;
var rightMouse = false;

pub var mainWindow: ?w.HWND = undefined;
pub var hookHandle: ?w.HHOOK = undefined;

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
        else => @enumFromInt(s),
    };
}

const d = @import("drawLabels.zig");
const pos = d.pos;
