pub const horizonthal = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"; // "QWFPBARSTGZXCDV";
pub const vertical = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"; //"JLUY;KNEIOM,.-"

pub const boardlineLen = 10;
pub const boardHeight = 3;
pub const board: *const [boardlineLen * boardHeight:0]u8 = "QWFPBJLUY;ARSTGKNEIOZXCDVMH,.-";

pub fn keyHandler(nCode: i32, wParam: w.WPARAM, lParam: w.LPARAM) callconv(.c) w.LRESULT {
    return blk: {
        if (nCode == w.HC_ACTION and wParam == w.WM_KEYDOWN) {
            const kbd: *w.KBDLLHOOKSTRUCT = @ptrFromInt(@as(usize, @intCast(lParam)));
            const vk: w.VIRTUAL_KEY = @enumFromInt(kbd.vkCode);

            if (vk == w.VK_F17) {
                _ = w.SendMessageW(@ptrFromInt(0xFFFF), w.WM_SYSCOMMAND, w.SC_MONITORPOWER, 2);
                break :blk 1;
            }
            if (vk == w.VK_F14) {
                l.changeOnAllWindows(l.langs.koreanEn);
                break :blk 1;
            }
            if (vk == w.VK_F15) {
                l.changeOnAllWindows(l.langs.russian);
                break :blk 1;
            }

            if (vk == w.VK_F16) {
                l.changeOnAllWindows(l.langs.kazakh);
                break :blk 1;
            }

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

            if (vk == w.VK_SPACE and mode == .Grid) {
                mode = .ColChosen;
                placeCursor(lastPos);
                break :blk 1;
            }

            if (vk == w.VK_ESCAPE and mode != .Hidden) {
                hide();
                break :blk 1;
            }
            if (vk == w.VK_TAB and mode != .Hidden) {
                rightMouse = !rightMouse;
                break :blk 1;
            }
            if (mode == .ColChosen and vk == w.VK_SPACE) {
                hide();
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
                    // w.LoadKeyboardLayoutA(pwszKLID: ?[*:0]const u8, Flags: ACTIVATE_KEYBOARD_LAYOUT_FLAGS)
                }
            }
            if (mode == .ColChosen) {
                for (board, 0..) |key, boardPos| {
                    if (letterToVK(key) == vk) {
                        hide();
                        click(SubgridPos(boardPos));
                        break :blk 1;
                    }
                }
            }
        }
        break :blk w.CallNextHookEx(hookHandle, nCode, wParam, lParam);
    };
}

fn hide() void {
    mode = .Hidden;
    _ = w.ShowWindow(mainWindow, w.SW_HIDE);
}

fn placeCursor(p: pos) void {
    _ = w.SetCursorPos(p.x, p.y);
}

var lastPos = pos{ .x = 0, .y = 0 };
fn click(p: pos) void {
    lastPos = p;
    placeCursor(p);
    w.mouse_event(if (rightMouse) w.MOUSEEVENTF_RIGHTDOWN else w.MOUSEEVENTF_LEFTDOWN, p.x, p.y, 0, 0);
    w.mouse_event(if (rightMouse) w.MOUSEEVENTF_RIGHTUP else w.MOUSEEVENTF_LEFTUP, p.x, p.y, 0, 0);
}

fn CellLeftUpCorner() pos {
    return .{
        .x = @divTrunc(cursor.x * s.screenSize.x, s.axisSize.x),
        .y = @divTrunc(cursor.y * s.screenSize.y, s.axisSize.y),
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

pub fn letterToVK(letter: u8) w.VIRTUAL_KEY {
    return switch (letter) {
        '-' => w.VK_RETURN,
        ';' => w.VK_OEM_1,
        ',' => w.VK_OEM_COMMA,
        '.' => w.VK_OEM_PERIOD,

        else => @enumFromInt(letter),
    };
}

const d = @import("drawLabels.zig");
const s = @import("screen.zig");
const pos = s.pos;
const l = @import("langSwitcher.zig");
