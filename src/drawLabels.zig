var label: [1:0]u16 = undefined;
pub fn drawLabels(hwnd: ?w.HWND) void {
    const hInstance = w.GetModuleHandleW(null);

    g_hFont = w.CreateFontW(
        25,
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

    boardSize = pos{ .x = @divTrunc(s.screenSize.x, m.boardlineLen), .y = @divTrunc(s.screenSize.y, m.boardHeight) };
    labelSize = pos{ .x = @divTrunc(boardSize.x, m.boardlineLen), .y = @divTrunc(boardSize.y, m.boardHeight) };
    for (0.., m.board) |i, letter| {
        label[0] = letter;
        const p = SubgridPos(i, boardSize, pos{ .x = 0, .y = 0 });
        const newLabel = w.CreateWindowExW(.{}, w.L("STATIC"), &label, .{
            .VISIBLE = 1,
            .CHILD = 1,
            .BORDER = 1,
            .ACTIVECAPTION = 1, // .CENTER
        }, p.x, p.y, labelSize.x, labelSize.y, hwnd, null, hInstance, null) orelse @panic("Failed creating label");
        _ = w.SendMessageW(newLabel, w.WM_SETFONT, @intCast(@intFromPtr(g_hFont)), 1);

        // _ = w.SetTextColor(w.GetDC(newLabel), z.packRgb(255, 255, 255)); // white text
        // _ = w.SetBkColor(w.GetDC(newLabel), z.packRgb(180, 80, 80)); // red background
        // _ = w.SetBkMode(w.GetDC(newLabel), w.TRANSPARENT);
    }
}

pub fn SubgridPos(boardPos: usize, size: pos, corner: pos) pos {
    const subRow = boardPos / m.boardlineLen;
    const subCol = boardPos % m.boardlineLen;
    const result = pos{
        .x = corner.x + @divTrunc((@as(i32, @intCast(subCol)) * size.x), m.boardlineLen),
        .y = corner.y + @divTrunc((@as(i32, @intCast(subRow)) * size.y), m.boardHeight),
    };
    return result;
}

pub var boardSize = pos{ .x = 0, .y = 0 };
pub var labelSize = pos{ .x = 0, .y = 0 };

pub var g_hFont: ?w.HFONT = undefined;

const win32 = @import("win32");
const w = win32.everything;
const m = @import("machine.zig");
const s = @import("screen.zig");
const pos = s.pos;
