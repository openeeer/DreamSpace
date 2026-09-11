# DreamSpace — ассеты для генерации

Сначала пришли **moon_library** и **cosmic_background**. После утверждения этой пары генерируй остальные изображения с Moon Library как style reference. Интерфейс уже ожидает указанные имена; изображения автоматически заменят временные обложки после пересборки.

## Требования

- Никаких надписей, кнопок, рамок, телефона или UI внутри изображения.
- Цветовое пространство sRGB.
- Обложки: мастер PNG 2048×1536 (4:3); в приложении WebP 1600×1200.
- Главный объект справа, примерно на 65–75% ширины; левая треть тёмная и спокойная для текста.
- Основной объект должен читаться и при круглом кадрировании.
- Фон: PNG/WebP 1440×3120. Не прозрачный.
- Отдельный туман: 1600×1000, настоящий alpha, без нарисованной шахматной сетки.
- Можно предоставить PNG: преобразование и оптимизацию сделаем при интеграции.

## Общий суффикс для всех восьми обложек

Добавляй этот текст **после каждого промпта обложки**:

> Premium cinematic dreamscape illustration for DreamSpace, sophisticated storybook realism, deep midnight blue and indigo palette, restrained lavender rim lighting, subtle warm moonlit gold, soft volumetric clouds, elegant atmospheric depth, detailed focal subject with calm low-detail negative space, consistent art direction, polished fantasy editorial artwork. No typography, no letters, no logos, no watermark, no UI, no borders, no phone mockup, no excessive bloom, no neon cyberpunk, no cartoon emoji style. Horizontal 4:3 composition.

## 1. assets/dreams/moon_library.webp

> A magnificent gothic library floating above lavender clouds on the RIGHT HALF of the composition. A huge softly luminous pale-gold moon rises behind the library. An elegant illuminated staircase climbs from the lower center-right into the entrance. Three small open books drift nearby. Place the architectural focal point around 70 percent of the image width. Keep the LEFT 42 percent as dark indigo mist with very low detail for a title overlay. Rich architectural detail, warm windows, dreamlike quiet grandeur. Preserve the library and staircase within a central-right square crop. Beautiful, believable architectural proportions, subtle moon surface texture, calm luminous atmosphere.

## 2. assets/backgrounds/cosmic_background.webp

> Vertical 6:13 atmospheric background for a premium dream journal. Almost-black midnight blue space with delicate indigo nebula clouds concentrated along the outer edges and bottom corners. The central 65 percent stays very dark, quiet and low contrast for readable interface content. Sparse tiny distant stars, a few restrained lavender pinpoints, extremely subtle cosmic dust. No large moon, no planets, no buildings, no horizon, no bright central objects. Smooth tonal transitions, premium cinematic depth. No text, no UI, no frame, no phone mockup. Full bleed.

## 3. assets/dreams/ocean_without_end.webp

> An endless still midnight ocean merging with an indigo sky, a small empty wooden boat in the center-right, a pale moon low on the horizon, a narrow silver-lavender reflection on the water, distant soft fog, extraordinary peaceful scale. Keep the left third darker and quieter for text. The focal boat and moon remain readable in a square crop. Restrained light, no dramatic storm. A feeling of infinite calm and being gently carried by the night.

## 4. assets/dreams/red_forest.webp

> A mysterious forest of tall slender trees with muted burgundy and dusty crimson leaves, embedded in a predominantly midnight-blue and violet dream world. A small ancient doorway glows softly between trees on the center-right, a winding dark path, low lavender mist, distant indistinct human silhouette. Elegant surreal atmosphere, curiosity rather than horror, no gore. Left third dark and uncluttered. Refined red accents, no bright red wash.

## 5. assets/dreams/empty_city.webp

> An empty dream city at blue hour beneath an indigo night sky, elegant old European facades, a quiet wet street reflecting a few lavender windows, one distant golden streetlamp, impossible subtle perspective disappearing into fog. No crowds, no cars, no readable signs. Melancholic cinematic stillness. Main street opening on the center-right, dark low-detail left third, subtle reflections and exquisite architectural details.

## 6. assets/dreams/glass_staircase.webp

> A delicate translucent glass staircase suspended in midnight-blue space, rising diagonally from lower center toward the upper right, soft lavender edges and tiny pale-gold reflections, distant moon behind thin clouds, a subtle floating mirror beside the upper landing. Beautiful impossible architecture, highly refined glass material, calm sparse composition. Dark quiet left third. Readable staircase silhouette in a square crop. A sense of quiet ascent into the unknown.

## 7. assets/dreams/last_train.webp

> A vintage midnight-blue passenger train waiting at an almost empty dream station, warm amber windows, a single old clock with no readable numerals, lavender fog swallowing the tracks, subtle stars above the platform roof. One tiny distant traveler silhouette, wistful and intimate mood. Train focal point on the center-right, dark low-detail space on the left. No readable signage, no prominent modern objects.

## 8. assets/dreams/sky_islands.webp

> A small collection of floating islands above an ocean of soft lavender clouds under a deep indigo starry sky. The main island on the center-right holds a single graceful ancient tree, tiny waterfalls disappear into the mist, a pale-gold crescent moon in the distance. Wonder, lightness and quiet joy, refined cinematic storybook realism, mostly cool colors with sparse warm accents. Dark calm left third. A clear graceful silhouette for a circular crop.

## 9. assets/dreams/door_under_water.webp

> An ancient freestanding doorway on the floor of a deep midnight-blue ocean, positioned center-right, a soft warm moonlike light shining through the open door, delicate stairs leading to it, suspended particles and restrained blue caustics, distant shadowy rocks, profound dreamlike stillness. No divers, no sea monsters, no text. Left third dark and low detail. Door clearly recognizable in a square crop, luminous threshold contrasting against a very dark ocean.

## 10. assets/backgrounds/nebula_foreground.webp — второй приоритет

> An isolated wispy bank of midnight-indigo and muted lavender dream clouds, panoramic 8:5 composition, soft translucent edges fading naturally to full transparency, subtle cool moonlight along a few cloud rims, sparse fine dust, quiet center, usable as a foreground parallax overlay. Transparent alpha background, no sky rectangle, no stars with hard edges, no objects, no typography, no frame, no checkerboard pattern baked into the image.

## 11. assets/branding/app_icon.png — 1024×1024

> A premium mobile app icon concept for DreamSpace: one sculptural pearl-lavender crescent moon embracing a tiny four-point star, centered on a deep midnight-indigo background, subtle dimensional shading and a restrained soft halo, bold simple silhouette readable at 48 pixels, generous clear padding around the symbol. Square full-bleed composition, no rounded corners baked in, no text, no border, no tiny scenery, no excessive sparkle. Elegant, distinctive, quiet and magical.

Для Android затем нужен прозрачный foreground символа. Его подготовим из утверждённого исходника, а не генерируем повторно.

## 12. Звуки — второй приоритет

`assets/audio/dream_saved.wav` — WAV PCM 44.1 kHz, 16-bit, mono:

> A single soft crystalline confirmation chime for a premium dream journal, gentle warm bell attack, subtle airy shimmer, very short smooth decay, intimate and calming, 0.5 seconds, no melody, no voice, no background ambience, no sharp transient, export dry mono WAV.

`assets/audio/constellation_open.wav`:

> A very quiet airy glass resonance suggesting a small constellation opening, one soft ascending shimmer with a smooth fade, elegant and restrained, 0.7 seconds, no orchestral swell, no voice, no loop, no background noise, export dry mono WAV.

## Генерировать не нужно

- Текст, интерфейс, кнопки, стеклянные панели, градиенты, звёзды и линии карты.
- Структурные иконки: единый набор Cupertino Icons уже включён.
- Шрифты: Lora и Inter уже включены локально с OFL-лицензиями.
- Отдельные изображения карты: узлы используют обложки снов.
- Отдельные onboarding-иллюстрации: используются те же обложки.

## Передача

Пришли изображения с указанными именами, желательно архивом. Если генератор умеет только другое разрешение, сохрани пропорции и предоставь максимальный оригинал. Не увеличивай маленькое изображение искусственно. Финальная проверка — читаемость обложки на ширине 350 px и узнаваемость объекта в круге 64 px.
