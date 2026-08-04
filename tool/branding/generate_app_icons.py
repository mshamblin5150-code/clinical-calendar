from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
APP_ROOT = REPOSITORY_ROOT / "apps" / "clinical_calendar"
MASTER_PATH = (
    APP_ROOT / "assets" / "branding" / "clinical_calendar_app_icon_master.png"
)


def resized(source: Image.Image, size: int) -> Image.Image:
    return source.resize((size, size), Image.Resampling.LANCZOS)


def save_png(source: Image.Image, destination: Path, size: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    resized(source, size).save(destination, format="PNG", optimize=True)


def generate_android(source: Image.Image) -> None:
    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    resource_root = APP_ROOT / "android" / "app" / "src" / "main" / "res"
    for directory, size in sizes.items():
        save_png(source, resource_root / directory / "ic_launcher.png", size)


def generate_ios(source: Image.Image) -> None:
    icon_root = APP_ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    contents = json.loads((icon_root / "Contents.json").read_text(encoding="utf-8"))
    generated: dict[str, int] = {}
    for entry in contents["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        logical_size = float(entry["size"].split("x", maxsplit=1)[0])
        scale = int(entry["scale"].removesuffix("x"))
        generated[filename] = round(logical_size * scale)
    for filename, size in generated.items():
        save_png(source, icon_root / filename, size)


def generate_windows(source: Image.Image) -> None:
    resource_root = APP_ROOT / "windows" / "runner" / "resources"
    resource_root.mkdir(parents=True, exist_ok=True)
    source.save(
        resource_root / "app_icon.ico",
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )
    save_png(source, resource_root / "app_icon_44.png", 44)
    save_png(source, resource_root / "app_icon_150.png", 150)


def main() -> None:
    with Image.open(MASTER_PATH) as image:
        source = image.convert("RGB")
        if source.width != source.height:
            raise ValueError("The master app icon must be square.")
        if source.width < 1024:
            raise ValueError("The master app icon must be at least 1024x1024.")
        generate_android(source)
        generate_ios(source)
        generate_windows(source)
    print(f"Generated app icons from {MASTER_PATH}")


if __name__ == "__main__":
    main()
