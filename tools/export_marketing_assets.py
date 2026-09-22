from pathlib import Path
from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
MARKETING = ROOT / "assets" / "marketing"
BRANDING = ROOT / "assets" / "branding"

SQUARE = Path(r"C:\Users\Giles\.codex\generated_images\01a00b32-cea8-7d63-a49d-df9a2c6c268b\exec-b4b1db41-a5ed-410e-95db-a308ab4f10a5.png")
LANDSCAPE = Path(r"C:\Users\Giles\.codex\generated_images\01a00b32-cea8-7d63-a49d-df9a2c6c268b\exec-2fd4b115-eb89-45b8-9f26-66d104f820e6.png")
STORY = Path(r"C:\Users\Giles\.codex\generated_images\01a00b32-cea8-7d63-a49d-df9a2c6c268b\exec-97c23d3e-2074-4c60-8bdf-cc8d8c21585c.png")


def cover(source: Path, output: Path, size: tuple[int, int]) -> None:
    image = Image.open(source).convert("RGB")
    source_ratio = image.width / image.height
    target_ratio = size[0] / size[1]
    if source_ratio > target_ratio:
        width = round(image.height * target_ratio)
        left = (image.width - width) // 2
        image = image.crop((left, 0, left + width, image.height))
    else:
        height = round(image.width / target_ratio)
        top = (image.height - height) // 2
        image = image.crop((0, top, image.width, top + height))
    image.resize(size, Image.Resampling.LANCZOS).save(output, optimize=True)


def main() -> None:
    MARKETING.mkdir(parents=True, exist_ok=True)
    BRANDING.mkdir(parents=True, exist_ok=True)

    cover(SQUARE, MARKETING / "mycarapp-social-square-1080.png", (1080, 1080))
    cover(SQUARE, MARKETING / "mycarapp-google-ads-square-1200.png", (1200, 1200))
    cover(LANDSCAPE, MARKETING / "mycarapp-google-ads-landscape-1200x628.png", (1200, 628))
    cover(STORY, MARKETING / "mycarapp-story-1080x1920.png", (1080, 1920))

    icon = Image.open(ROOT / "assets" / "mycarapp_icon.png").convert("RGBA")
    for size in (16, 32, 48, 180, 192, 512):
        resized = icon.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(BRANDING / f"mycarapp-icon-{size}x{size}.png", optimize=True)
    icon.save(
        BRANDING / "favicon.ico",
        format="ICO",
        sizes=[(16, 16), (32, 32), (48, 48)],
    )


if __name__ == "__main__":
    main()
