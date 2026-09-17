from pathlib import Path
from typing import List, Tuple

from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "promo" / "xiaohongshu" / "sources"
OUT = ROOT / "docs" / "promo" / "xiaohongshu"
W, H = 1242, 1660

PAPER = "#F2FAFD"
NAVY = "#10263D"
BLUE = "#2F7EF7"
MUTED = "#6B8298"
WHITE = "#FFFFFF"
SKY = "#D9F4F4"
PINK = "#FFE7ED"
YELLOW = "#FFF3C8"
GREEN = "#DDF6EA"

REGULAR = r"C:\Windows\Fonts\msyh.ttc"
BOLD = r"C:\Windows\Fonts\msyhbd.ttc"


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(BOLD if bold else REGULAR, size)


def round_rect(draw: ImageDraw.ImageDraw, box: Tuple[int, int, int, int],
               radius: int, fill: str) -> None:
    left, top, right, bottom = box
    draw.rectangle((left + radius, top, right - radius, bottom), fill=fill)
    draw.rectangle((left, top + radius, right, bottom - radius), fill=fill)
    draw.pieslice((left, top, left + radius * 2, top + radius * 2), 180, 270, fill=fill)
    draw.pieslice((right - radius * 2, top, right, top + radius * 2), 270, 360, fill=fill)
    draw.pieslice((left, bottom - radius * 2, left + radius * 2, bottom), 90, 180, fill=fill)
    draw.pieslice((right - radius * 2, bottom - radius * 2, right, bottom), 0, 90, fill=fill)


def draw_text(draw: ImageDraw.ImageDraw, xy: Tuple[int, int], value: str,
              size: int, color: str = NAVY, bold: bool = False) -> None:
    draw.text(xy, value, font=font(size, bold), fill=color)


def phone_mask(size: Tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    round_rect(ImageDraw.Draw(mask), (0, 0, size[0] - 1, size[1] - 1), radius, "#FFFFFF")
    return mask


def paste_phone(canvas: Image.Image, source_name: str) -> None:
    screenshot = Image.open(SOURCE / source_name).convert("RGB")
    if source_name == "raw_recurring.png":
        screenshot_draw = ImageDraw.Draw(screenshot)
        item_background = screenshot.getpixel((600, 2000))
        screenshot_draw.rectangle((338, 1978, 600, 2056), fill=item_background)
        screenshot_draw.text((346, 1985), "房租", font=font(42, True), fill=NAVY)
    target_h = 1240
    target_w = int(screenshot.width * target_h / screenshot.height)
    screenshot = screenshot.resize((target_w, target_h), Image.LANCZOS)
    x = (W - target_w) // 2
    y = 355

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    round_rect(shadow_draw, (x - 18, y - 12, x + target_w + 22, y + target_h + 26), 52, "#B8CBD8")
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    canvas.paste(shadow, (0, 0), shadow)

    frame = Image.new("RGB", (target_w + 34, target_h + 34), WHITE)
    frame_mask = phone_mask(frame.size, 48)
    canvas.paste(frame, (x - 17, y - 17), frame_mask)
    canvas.paste(screenshot, (x, y), phone_mask(screenshot.size, 38))


def tag(draw: ImageDraw.ImageDraw, xy: Tuple[int, int], value: str,
        fill: str, color: str = NAVY) -> None:
    label_font = font(25, True)
    width = draw.textsize(value, font=label_font)[0] + 42
    x, y = xy
    round_rect(draw, (x, y, x + width, y + 56), 28, fill)
    draw.text((x + 21, y + 12), value, font=label_font, fill=color)


def render(index: int, title: str, subtitle: str, source_name: str,
           tags: List[Tuple[str, str]]) -> None:
    canvas = Image.new("RGB", (W, H), PAPER)
    draw = ImageDraw.Draw(canvas)
    draw.ellipse((W - 300, -120, W + 90, 270), fill=SKY)
    draw.ellipse((-115, H - 245, 245, H + 115), fill=PINK)
    draw.rectangle((0, 0, 24, H), fill=BLUE)

    draw_text(draw, (62, 52), "一页账  /  HARMONYOS", 25, BLUE, True)
    draw_text(draw, (1150, 50), f"0{index}", 27, NAVY, True)
    draw_text(draw, (62, 105), title, 60, NAVY, True)
    draw_text(draw, (64, 190), subtitle, 27, MUTED)
    draw.rectangle((64, 246, 180, 256), fill=BLUE)

    paste_phone(canvas, source_name)
    tag(draw, (54, 300), tags[0][0], tags[0][1])
    first_width = draw.textsize(tags[0][0], font=font(25, True))[0] + 42
    tag(draw, (72 + first_width, 300), tags[1][0], tags[1][1])

    canvas.save(OUT / f"{index:02d}.png", quality=96)


def main() -> None:
    pages = [
        ("记账别靠毅力", "收入、支出、预算和流水，一眼看清", "raw_home.png",
         [("今日总览", YELLOW), ("本月结余", GREEN)]),
        ("少点几下，记完一笔", "支出、收入、转账和快捷模板都在一页", "raw_record.png",
         [("快捷模板", SKY), ("多账本", YELLOW)]),
        ("钱花去哪，报表告诉你", "周、月、季、年和自定义周期随时复盘", "raw_stats.png",
         [("现金流评分", SKY), ("收入节奏", GREEN)]),
        ("工资怎么花，心里有数", "按月薪换算支出，看到真实消费进度", "raw_salary.png",
         [("工资进度", YELLOW), ("收入拆解", PINK)]),
        ("固定收支，不用重复记", "房租、会员、工资等账单按周期生成", "raw_recurring.png",
         [("周期账单", SKY), ("到期生成", GREEN)]),
        ("不用打开 App，也能看账", "桌面卡片同步今日、本月、收入与结余", "current-card-page.png",
         [("桌面卡片", SKY), ("自动汇总", GREEN)]),
        ("股票基金，也放进总资产", "最近价格与净值自动更新，市值盈亏一眼看清", "raw_investment.jpeg",
         [("独立持仓", SKY), ("自动更新", GREEN)]),
    ]
    for index, page in enumerate(pages, 1):
        render(index, *page)
    print(f"Generated {len(pages)} current-version promo images in {OUT}")


if __name__ == "__main__":
    main()
