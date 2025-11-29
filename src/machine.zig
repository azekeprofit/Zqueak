const win32 = @import("win32");
const w = win32.everything;

const Modes = enum {
    Hidden,
    Grid,
    RowChosen,
    ColChosen,
};
pub fn letterToVK(s: c_char) w.VIRTUAL_KEY {
    return switch (s) {
        '-' => w.VK_RETURN,
        ';' => w.VK_SEMICOLON,
        ',' => w.VK_OEM_COMMA,
        '.' => w.VK_OEM_PERIOD,
        _ => s - 'a' + w.VK_A,
    };
}

const horizonthal = "qwfpbarstgzxcdvjluykneiomh"; // "qwfpbarstgzxcdv";
const vertical = "qwfpbarstgzxcdvjluykneiomh"; //"jluy;kneiom,.-";

const boardlineLen = 10;
const boardHeight = 3;
const boardChars = "qwfpbjluy;arstgkneiozxcdvmh,.-";

//    private bool rightMouse = false;
