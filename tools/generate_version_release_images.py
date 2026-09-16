from pathlib import Path
from typing import List, Tuple

from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "promo" / "xiaohongshu" / "sources"
BASE_OUT = ROOT / "docs" / "promo" / "xiaohongshu"

PAPER = "#F2FAFD"
NAVY = "#10263D"
BLUE = "#2F7EF7"
MUTED = "#6B8298"
WHITE = "#FFFFFF"
SKY = "#D9F4F4"
PINK = "#FFE7ED"

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


def rounded_mask(size: Tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    round_rect(ImageDraw.Draw(mask), (0, 0, size[0] - 1, size[1] - 1), radius, "#FFFFFF")
    return mask


def prepare_screenshot(source_name: str) -> Image.Image:
    screenshot = Image.open(SOURCE / source_name).convert("RGB")
    if source_name == "raw_recurring.png":
        draw = ImageDraw.Draw(screenshot)
        background = screenshot.getpixel((600, 2000))
        draw.rectangle((338, 1978, 600, 2056), fill=background)
        draw.text((346, 1985), "房租", font=font(42, True), fill=NAVY)
    return screenshot


def paste_device(canvas: Image.Image, source_name: str, top: int, height: int) -> None:
    screenshot = prepare_screenshot(source_name)
    width = int(screenshot.width * height / screenshot.height)
    screenshot = screenshot.resize((width, height), Image.LANCZOS)
    left = (canvas.width - width) // 2

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    round_rect(
        shadow_draw,
        (left - 18, top - 12, left + width + 24, top + height + 30),
        52,
        "#B4C8D5",
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    canvas.paste(shadow, (0, 0), shadow)

    frame_size = (width + 34, height + 34)
    frame = Image.new("RGB", frame_size, WHITE)
    canvas.paste(frame, (left - 17, top - 17), rounded_mask(frame_size, 48))
    canvas.paste(screenshot, (left, top), rounded_mask(screenshot.size, 38))


def render(size: Tuple[int, int], title: str, subtitle: str,
           source_name: str, output: Path) -> None:
    width, height = size
    canvas = Image.new("RGB", size, PAPER)
    draw = ImageDraw.Draw(canvas)

    draw.ellipse((width - 310, -105, width + 75, 280), fill=SKY)
    draw.ellipse((-120, height - 255, 250, height + 115), fill=PINK)
    draw.rectangle((0, 0, 22, height), fill=BLUE)

    left = 58 if width == 1080 else 90
    draw.text((left, 62), "一页账  /  HARMONYOS", font=font(24, True), fill=BLUE)
    draw.text((left, 112), title, font=font(54, True), fill=NAVY)
    draw.text((left, 190), subtitle, font=font(28), fill=MUTED)
    draw.rectangle((left, 248, left + 112, 258), fill=BLUE)

    device_height = 1510
    paste_device(canvas, source_name, 330, device_height)
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output, "JPEG", quality=95, subsampling=0)


def generate_set(folder: str, prefix: str, size: Tuple[int, int],
                 pages: List[Tuple[str, str, str, str]]) -> None:
    output_dir = BASE_OUT / folder
    for slug, title, subtitle, source_name in pages:
        render(size, title, subtitle, source_name, output_dir / f"{prefix}_{slug}.jpg")


def main() -> None:
    pages = [
        ("home", "记账别靠毅力", "收入、支出、预算和流水，一眼看清", "raw_home.png"),
        ("record", "少点几下，记完一笔", "支出、收入、转账和快捷模板都在一页", "raw_record.png"),
        ("stats", "钱花去哪，报表告诉你", "多种统计周期，随时复盘现金流", "raw_stats.png"),
        ("salary", "工资怎么花，心里有数", "按月薪换算支出，看到真实消费进度", "raw_salary.png"),
        ("recurring", "固定收支，不用重复记", "房租、会员、工资等账单按周期生成", "raw_recurring.png"),
        ("widget", "不用打开 App，也能看账", "桌面同步今日、本月、收入与结余", "current-card-page.png"),
    ]
    generate_set("release-phone", "phone", (1080, 1920), pages)
    generate_set("release-tablet", "tablet", (1280, 1920), pages)
    print("Generated 12 version-release JPEG images")


if __name__ == "__main__":
    main()
