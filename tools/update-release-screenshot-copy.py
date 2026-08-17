from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
FONT_DIR = Path("C:/Windows/Fonts")


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_DIR / name), size)


BOLD = "msyhbd.ttc"
REGULAR = "msyh.ttc"


def draw_text(draw: ImageDraw.ImageDraw, xy, text: str, size: int, color: str, bold: bool = False) -> None:
    draw.text(xy, text, font=font(BOLD if bold else REGULAR, size), fill=color)


def round_rect(draw: ImageDraw.ImageDraw, box, radius: int, fill: str) -> None:
    left, top, right, bottom = box
    draw.rectangle((left + radius, top, right - radius, bottom), fill=fill)
    draw.rectangle((left, top + radius, right, bottom - radius), fill=fill)
    draw.pieslice((left, top, left + radius * 2, top + radius * 2), 180, 270, fill=fill)
    draw.pieslice((right - radius * 2, top, right, top + radius * 2), 270, 360, fill=fill)
    draw.pieslice((left, bottom - radius * 2, left + radius * 2, bottom), 90, 180, fill=fill)
    draw.pieslice((right - radius * 2, bottom - radius * 2, right, bottom), 0, 90, fill=fill)


def patch_phone() -> None:
    path = ROOT / "release-screenshots" / "phone_manage.jpg"
    img = Image.open(path).convert("RGB")
    draw = ImageDraw.Draw(img)

    page_bg = "#EAF8FC"
    card_bg = "#FFFFFF"
    icon_bg = "#E8F8F3"
    title = "#08243A"
    muted = "#647386"
    accent = "#2BBF9F"

    draw.rectangle((68, 156, 600, 206), fill=page_bg)
    draw_text(draw, (72, 160), "分类、预算、导出集中管理", 30, muted, True)

    draw.rectangle((266, 804, 800, 858), fill=card_bg)
    draw_text(draw, (267, 819), "管理分类、预算、导出和偏好设置。", 24, muted)

    round_rect(draw, (256, 1442, 328, 1514), 20, icon_bg)
    draw_text(draw, (277, 1458), "导", 30, accent, True)
    draw.rectangle((346, 1452, 748, 1538), fill=card_bg)
    draw_text(draw, (348, 1458), "数据导出", 30, title, True)
    draw_text(draw, (348, 1510), "导出 CSV 账单", 23, muted)

    img.save(path, quality=95)


def patch_tablet() -> None:
    path = ROOT / "release-screenshots" / "tablet_manage.jpg"
    img = Image.open(path).convert("RGB")
    draw = ImageDraw.Draw(img)

    page_bg = "#EAF8FC"
    card_bg = "#FFFFFF"
    icon_bg = "#E8F8F3"
    title = "#08243A"
    muted = "#647386"
    accent = "#2BBF9F"

    draw.rectangle((88, 168, 650, 220), fill=page_bg)
    draw_text(draw, (92, 174), "分类、预算、导出集中管理", 30, muted, True)

    draw.rectangle((368, 792, 900, 856), fill=card_bg)
    draw_text(draw, (369, 817), "管理分类、预算、导出和偏好设置。", 24, muted)

    round_rect(draw, (356, 1434, 428, 1506), 20, icon_bg)
    draw_text(draw, (377, 1450), "导", 30, accent, True)
    draw.rectangle((448, 1446, 850, 1532), fill=card_bg)
    draw_text(draw, (450, 1452), "数据导出", 30, title, True)
    draw_text(draw, (450, 1504), "导出 CSV 账单", 23, muted)

    img.save(path, quality=95)


if __name__ == "__main__":
    patch_phone()
    patch_tablet()
