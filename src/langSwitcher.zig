fn tryToChange(hWnd: w.HWND, _: w.LPARAM) callconv(.winapi) w.BOOL {
    if (w.IsWindowVisible(hWnd) != 0) {
        const langId = switch (lang) {
            .koreanEn => w.L("00000412"),
            .russian => w.L("00000419"),
            .kazakh => w.L("0000043F"),
        };
        const hkl = w.LoadKeyboardLayoutW(langId, w.KLF_ACTIVATE) orelse @panic("language not found");
        _ = w.PostMessageW(hWnd, w.WM_INPUTLANGCHANGEREQUEST, 0, @bitCast(@intFromPtr(hkl))); // cast HKL into LPARAM (isize)
    }
    return 1;
}

pub fn changeOnAllWindows(l: langs) void {
    lang = l;
    _ = w.EnumWindows(tryToChange, 0);
}

var lang: langs = .koreanEn;
pub const langs = enum { koreanEn, russian, kazakh };

const win32 = @import("win32");
const w = win32.everything;
