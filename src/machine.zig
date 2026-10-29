pub const horizonthal = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"; // "QWFPBARSTGZXCDV";
pub const vertical = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"; //"JLUY;KNEIOM,.-"

pub const boardlineLen = 10;
pub const boardHeight = 3;
pub const board: *const [boardlineLen * boardHeight:0]u8 = "QWFPBJLUY;ARSTGKNEIOZXCDVMH,.-";


pub fn keyHandler(nCode: i32, wParam: w.WPARAM, lParam: w.LPARAM) callconv(.c) w.LRESULT {
    return blk: {
        if (nCode == w.HC_ACTION and wParam == w.WM_KEYDOWN) {
            const vk=getKey(lParam);
            const now = w.GetTickCount64();

            if (vk == w.VK_N and (now-lastMouseTick)<mouseTimeout) {
                mouseClick(currentMouse(), .left);
                break :blk 1;
            }

            if (vk == w.VK_OEM_1 and (now-lastMouseTick)<mouseTimeout) {
                mouseClick(currentMouse(), .right);
                break :blk 1;
            }


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
        break :blk w.CallNextHookEx(kbHookHandle, nCode, wParam, lParam);
    };
}

pub fn mouseHandler(nCode: i32, wParam: w.WPARAM, lParam: w.LPARAM) callconv(.c) w.LRESULT {
    if (nCode == w.HC_ACTION and wParam == w.WM_MOUSEMOVE) {
        lastMouseTick=w.GetTickCount64();
    }
    return w.CallNextHookEx(mouseHookHandle, nCode, wParam, lParam);
}

fn hide() void {
    mode = .Hidden;
    _ = w.ShowWindow(mainWindow, w.SW_HIDE);
}

fn placeCursor(p: pos) void {
    _ = w.SetCursorPos(p.x, p.y);
}

fn currentMouse() pos {
    var r: pos = undefined;
     if(w.GetCursorPos(&r)==0){
         @panic("can't get mouse position");
     }
     return r;
}

const mouseButton=enum { left, right };

fn mouseClick(p:pos, button:mouseButton) void {
    w.mouse_event(if (button==.right) w.MOUSEEVENTF_RIGHTDOWN else w.MOUSEEVENTF_LEFTDOWN, p.x, p.y, 0, 0);
    w.mouse_event(if (button==.right) w.MOUSEEVENTF_RIGHTUP else w.MOUSEEVENTF_LEFTUP, p.x, p.y, 0, 0);
}

var lastPos = pos{ .x = 0, .y = 0 };
fn click(p: pos) void {
    lastPos = p;
    placeCursor(p);
    mouseClick(p, if(rightMouse) .right else .left);
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
    LeftMouseButtonHeld,
    RightMouseButtonHeld,
};

var mode: Modes = .Hidden;
var rightMouse = false;

const mouseTimeout:u64 = 400;
pub var mainWindow: ?w.HWND = undefined;
pub var kbHookHandle: ?w.HHOOK = undefined;
pub var mouseHookHandle: ?w.HHOOK = undefined;
pub var lastMouseTick: u64=0;

pub fn letterToVK(letter: u8) w.VIRTUAL_KEY {
    return switch (letter) {
        '-' => w.VK_RETURN,
        ';' => w.VK_OEM_1,
        ',' => w.VK_OEM_COMMA,
        '.' => w.VK_OEM_PERIOD,

        else => @fromBackingInt(letter),
    };
}

fn getKey(lParam:w.LPARAM) w.VIRTUAL_KEY {
    const kbd: *w.KBDLLHOOKSTRUCT = @ptrFromInt(@as(usize, @intCast(lParam)));
    return @fromBackingInt(@intCast(kbd.vkCode));
}

const d = @import("drawLabels.zig");
const s = @import("screen.zig");
const pos = s.pos;
const l = @import("langSwitcher.zig");
