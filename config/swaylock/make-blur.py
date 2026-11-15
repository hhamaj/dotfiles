# Kilit ekranı arka planı: duvar kâğıdının bulanık + koyulaştırılmış kopyası
# Kullanım: python3 make-blur.py <duvar_kağıdı> <çıktı.png>   (Pillow gerekir)
import sys
from PIL import Image, ImageFilter, ImageEnhance
src, dst = sys.argv[1], sys.argv[2]
W, H = 1920, 1080
im = Image.open(src).convert("RGB")
# "fill": oranı koruyarak ekranı doldur, taşanı kırp
s = max(W / im.width, H / im.height)
im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
l, t = (im.width - W) // 2, (im.height - H) // 2
im = im.crop((l, t, l + W, t + H))
im = im.resize((W // 4, H // 4), Image.LANCZOS).filter(ImageFilter.GaussianBlur(12)).resize((W, H), Image.LANCZOS)
im = ImageEnhance.Brightness(im).enhance(0.45)
im.save(dst)
