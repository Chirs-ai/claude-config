from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

W, H = 900, 383
BG = (250, 249, 246)
INK = (22, 22, 22)
GRAY = (140, 140, 140)
ACCENT = (178, 34, 34)

CJK = "C:/Windows/Fonts/simsun.ttc"
CJK_BOLD = "C:/Windows/Fonts/SimHei.ttf"
LATIN = "C:/Windows/Fonts/georgiab.ttf"
LATIN_REG = "C:/Windows/Fonts/georgia.ttf"

def is_latin(ch):
    return ord(ch) < 128 and (ch.isalnum() or ch in " ")

def draw_mixed(d, xy, text, cjk_font, latin_font, fill):
    x, y = xy
    buf = ""
    buf_is_latin = None
    for ch in text:
        cur = is_latin(ch)
        if buf and cur != buf_is_latin:
            font = latin_font if buf_is_latin else cjk_font
            d.text((x, y), buf, font=font, fill=fill)
            bbox = d.textbbox((x, y), buf, font=font)
            x = bbox[2]
            buf = ""
        buf += ch
        buf_is_latin = cur
    if buf:
        font = latin_font if buf_is_latin else cjk_font
        d.text((x, y), buf, font=font, fill=fill)
        bbox = d.textbbox((x, y), buf, font=font)
        x = bbox[2]
    return x

def measure_mixed(d, text, cjk_font, latin_font):
    x = 0
    buf = ""
    buf_is_latin = None
    for ch in text:
        cur = is_latin(ch)
        if buf and cur != buf_is_latin:
            font = latin_font if buf_is_latin else cjk_font
            bbox = d.textbbox((0, 0), buf, font=font)
            x += bbox[2]
            buf = ""
        buf += ch
        buf_is_latin = cur
    if buf:
        font = latin_font if buf_is_latin else cjk_font
        bbox = d.textbbox((0, 0), buf, font=font)
        x += bbox[2]
    return x

def render(out_path, main_lines, sub_line, accent_spans=None):
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)

    f_cjk = ImageFont.truetype(CJK_BOLD, 46)
    f_lat = ImageFont.truetype(LATIN, 46)
    f_cjk_sub = ImageFont.truetype(CJK, 22)
    f_lat_sub = ImageFont.truetype(LATIN_REG, 22)

    left = 80
    top = 96
    line_gap = 22

    bar_y = top - 26
    d.rectangle([left, bar_y, left + 44, bar_y + 4], fill=INK)

    y = top
    for line_idx, line in enumerate(main_lines):
        if accent_spans and line_idx in accent_spans:
            spans = accent_spans[line_idx]
            cursor = 0
            x = left
            for span_start, span_end in spans:
                if cursor < span_start:
                    seg = line[cursor:span_start]
                    x = draw_mixed(d, (x, y), seg, f_cjk, f_lat, INK)
                seg = line[span_start:span_end]
                x = draw_mixed(d, (x, y), seg, f_cjk, f_lat, ACCENT)
                cursor = span_end
            if cursor < len(line):
                seg = line[cursor:]
                draw_mixed(d, (x, y), seg, f_cjk, f_lat, INK)
        else:
            draw_mixed(d, (left, y), line, f_cjk, f_lat, INK)
        y += 46 + line_gap

    y += 18
    draw_mixed(d, (left, y), sub_line, f_cjk_sub, f_lat_sub, GRAY)

    img.save(out_path, "PNG")
    print(f"saved: {out_path}")

out_dir = Path(r"D:\projects\claude-config\output")
out_dir.mkdir(exist_ok=True)

line1 = "中文圈在刷「天壤之别」，"
line2 = "英文圈在喊「它会让 Claude 变聋」。"
sub = "同一份文件，两个世界。"

render(
    out_dir / "header_v2_plain.png",
    [line1, line2],
    sub,
)

accent_spans = {
    0: [(line1.index("「"), line1.index("」") + 1)],
    1: [(line2.index("「"), line2.index("」") + 1)],
}
render(
    out_dir / "header_v2_accent.png",
    [line1, line2],
    sub,
    accent_spans=accent_spans,
)
