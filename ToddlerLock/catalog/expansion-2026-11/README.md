# Расширение ноября 2026

Добавлены 40 животных и 40 домашних предметов: по десять для кухни, ванной, прихожей и комнаты. После расширения в игре 180 животных и 170 домашних вещей; вместе с транспортом — 400 карточек. Все 80 новых названий записаны голосом Kore, общий каталог содержит 524 офлайн-записи.

## Обзорные листы

- [Животные, 1–20](animals-preview-1.jpg)
- [Животные, 21–40](animals-preview-2.jpg)
- [Домашние предметы, 1–20](household-preview-1.jpg)
- [Домашние предметы, 21–40](household-preview-2.jpg)

## Проверка узнаваемости животных

Отдельно просмотрены все 180 животных. Для 13 карточек выбраны новые варианты с естественными пропорциями и выражением: косатка, нарвал, тюлень, дюгонь, ламантин, белуха, кашалот, дельфин, кит, скат, хамелеон, аксолотль и соня. Тюлень, дельфин, кит и скат заменяют прежние иллюстрации; девять остальных входят в новые 40 карточек.

Основные исправления: вытянутое тело и естественная окраска морских млекопитающих, бивень нарвала из верхней челюсти с целым кончиком, короткие передние ласты и низкая поза тюленя, разные формы хвостов ламантина и дюгоня, глаза ската по бокам головы вместо лица на брюшке. Убраны человеческие улыбки, румянец, брови и чрезмерно крупные глаза. У сони выделен длинный пушистый хвост, у хамелеона — глаза и цепкие лапы, у аксолотля — наружные жабры и вытянутое тело.

[Сравнение «было / стало»](animal-revisions-before-after.jpg). [Точные промпты выбранных перерисовок и сохранённые исходные версии](revisions.json). Исходные варианты сохранены, выбранные версии отмечены в `generation.json`.

Внешние признаки сверены с материалами [NOAA о нарвале](https://www.fisheries.noaa.gov/species/narwhal), [NOAA о косатке](https://www.fisheries.noaa.gov/species/killer-whale), [NOAA о тюлене](https://www.fisheries.noaa.gov/species/harbor-seal) и [FWS о ламантине](https://www.fws.gov/species/florida-manatee-trichechus-manatus-latirostris).

## Исходники и подготовка

Все иллюстрации созданы встроенным `image_gen`, по одному прозрачному изображению на карточку, в акварельно-гуашевом стиле текущего каталога. [Полные промпты и названия](items.json). Исходные PNG сохранены в `originals/`; [generation.json](generation.json) связывает их с игровыми PNG и содержит контрольные суммы обоих файлов.

`../../tools/import_november_expansion.py` обрезает прозрачное поле, масштабирует предмет до 440 пикселей и помещает его в центр RGBA PNG 512×512. Готовые файлы находятся в `../../ToddlerLock/Resources/Pictures/Animals/` и `../../ToddlerLock/Resources/Pictures/Household/`. Скрипт также создаёт четыре обзорных листа и сравнение выбранных перерисовок. Исходный AR может отличаться; все игровые изображения приводятся к квадратному прозрачному холсту 512×512 без растягивания, с максимальным размером объекта 440 пикселей и равными отступами по центру.

Озвучка подготовлена существующим OpenRouter-пайплайном с голосом Kore. Файлы WAV, PCM 24 кГц / 16 бит / моно, включены в приложение. Тексты, длительности и контрольные суммы — в [общем манифесте](../speech.json).

## Новые карточки

| Категория | Название | Картинка | Озвучка |
| --- | --- | --- | --- |
| Животные | бурундук | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-chipmunk.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-chipmunk.wav) |
| Животные | песец | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-arctic-fox.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-arctic-fox.wav) |
| Животные | росомаха | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-wolverine.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-wolverine.wav) |
| Животные | мангуст | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-mongoose.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-mongoose.wav) |
| Животные | дикобраз | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-porcupine.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-porcupine.wav) |
| Животные | тушканчик | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-jerboa.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-jerboa.wav) |
| Животные | соня | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-dormouse.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-dormouse.wav) |
| Животные | землеройка | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-shrew.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-shrew.wav) |
| Животные | горностай | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-stoat.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-stoat.wav) |
| Животные | ласка | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-weasel.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-weasel.wav) |
| Животные | норка | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-mink.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-mink.wav) |
| Животные | нутрия | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-coypu.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-coypu.wav) |
| Животные | ондатра | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-muskrat.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-muskrat.wav) |
| Животные | енотовидная собака | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-raccoon-dog.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-raccoon-dog.wav) |
| Животные | гиббон | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-gibbon.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-gibbon.wav) |
| Животные | горилла | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-gorilla.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-gorilla.wav) |
| Животные | орангутан | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-orangutan.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-orangutan.wav) |
| Животные | шимпанзе | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-chimpanzee.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-chimpanzee.wav) |
| Животные | носуха | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-coati.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-coati.wav) |
| Животные | лемур | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-lemur.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-lemur.wav) |
| Животные | квокка | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-quokka.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-quokka.wav) |
| Животные | валлаби | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-wallaby.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-wallaby.wav) |
| Животные | дюгонь | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-dugong.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-dugong.wav) |
| Животные | ламантин | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-manatee.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-manatee.wav) |
| Животные | нарвал | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-narwhal.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-narwhal.wav) |
| Животные | белуха | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-beluga.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-beluga.wav) |
| Животные | кашалот | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-sperm-whale.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-sperm-whale.wav) |
| Животные | косатка | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-orca.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-orca.wav) |
| Животные | сойка | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-jay.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-jay.wav) |
| Животные | чайка | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-seagull.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-seagull.wav) |
| Животные | баклан | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-cormorant.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-cormorant.wav) |
| Животные | фазан | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-pheasant.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-pheasant.wav) |
| Животные | цесарка | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-guineafowl.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-guineafowl.wav) |
| Животные | глухарь | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-capercaillie.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-capercaillie.wav) |
| Животные | колибри | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-hummingbird.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-hummingbird.wav) |
| Животные | саламандра | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-salamander.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-salamander.wav) |
| Животные | тритон | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-newt.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-newt.wav) |
| Животные | хамелеон | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-chameleon.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-chameleon.wav) |
| Животные | игуана | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-iguana.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-iguana.wav) |
| Животные | аксолотль | [PNG](../../ToddlerLock/Resources/Pictures/Animals/animal-axolotl.png) | [Kore](../../ToddlerLock/Resources/Speech/animal-axolotl.wav) |
| Кухня | кофеварка | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-coffee-maker.png) | [Kore](../../ToddlerLock/Resources/Speech/home-coffee-maker.wav) |
| Кухня | вафельница | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-waffle-maker.png) | [Kore](../../ToddlerLock/Resources/Speech/home-waffle-maker.wav) |
| Кухня | мультиварка | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-multicooker.png) | [Kore](../../ToddlerLock/Resources/Speech/home-multicooker.wav) |
| Кухня | подставка под горячее | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-trivet.png) | [Kore](../../ToddlerLock/Resources/Speech/home-trivet.wav) |
| Кухня | сито | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-sieve.png) | [Kore](../../ToddlerLock/Resources/Speech/home-sieve.wav) |
| Кухня | противень | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-baking-tray.png) | [Kore](../../ToddlerLock/Resources/Speech/home-baking-tray.wav) |
| Кухня | форма для выпечки | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-baking-tin.png) | [Kore](../../ToddlerLock/Resources/Speech/home-baking-tin.wav) |
| Кухня | кухонные весы | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-kitchen-scales.png) | [Kore](../../ToddlerLock/Resources/Speech/home-kitchen-scales.wav) |
| Кухня | кухонные щипцы | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-kitchen-tongs.png) | [Kore](../../ToddlerLock/Resources/Speech/home-kitchen-tongs.wav) |
| Кухня | сушилка для посуды | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-dish-rack.png) | [Kore](../../ToddlerLock/Resources/Speech/home-dish-rack.wav) |
| Ванная | ковшик | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-bath-dipper.png) | [Kore](../../ToddlerLock/Resources/Speech/home-bath-dipper.wav) |
| Ванная | мыльница | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-soap-dish.png) | [Kore](../../ToddlerLock/Resources/Speech/home-soap-dish.wav) |
| Ванная | стакан для щёток | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-toothbrush-holder.png) | [Kore](../../ToddlerLock/Resources/Speech/home-toothbrush-holder.wav) |
| Ванная | шапочка для душа | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-shower-cap.png) | [Kore](../../ToddlerLock/Resources/Speech/home-shower-cap.wav) |
| Ванная | полотенцесушитель | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-towel-warmer.png) | [Kore](../../ToddlerLock/Resources/Speech/home-towel-warmer.wav) |
| Ванная | пемза | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-pumice.png) | [Kore](../../ToddlerLock/Resources/Speech/home-pumice.wav) |
| Ванная | ватные палочки | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-cotton-swabs.png) | [Kore](../../ToddlerLock/Resources/Speech/home-cotton-swabs.wav) |
| Ванная | ватные диски | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-cotton-pads.png) | [Kore](../../ToddlerLock/Resources/Speech/home-cotton-pads.wav) |
| Ванная | детская ступенька | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-step-stool.png) | [Kore](../../ToddlerLock/Resources/Speech/home-step-stool.wav) |
| Ванная | ёршик | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-toilet-brush.png) | [Kore](../../ToddlerLock/Resources/Speech/home-toilet-brush.wav) |
| Прихожая | валенки | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-felt-boots.png) | [Kore](../../ToddlerLock/Resources/Speech/home-felt-boots.wav) |
| Прихожая | пальто | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-overcoat.png) | [Kore](../../ToddlerLock/Resources/Speech/home-overcoat.wav) |
| Прихожая | комбинезон | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-snowsuit.png) | [Kore](../../ToddlerLock/Resources/Speech/home-snowsuit.wav) |
| Прихожая | панама | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-bucket-hat.png) | [Kore](../../ToddlerLock/Resources/Speech/home-bucket-hat.wav) |
| Прихожая | шляпа | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-straw-hat.png) | [Kore](../../ToddlerLock/Resources/Speech/home-straw-hat.wav) |
| Прихожая | ремень | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-belt.png) | [Kore](../../ToddlerLock/Resources/Speech/home-belt.wav) |
| Прихожая | кошелёк | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-wallet.png) | [Kore](../../ToddlerLock/Resources/Speech/home-wallet.wav) |
| Прихожая | обувная щётка | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-shoe-brush.png) | [Kore](../../ToddlerLock/Resources/Speech/home-shoe-brush.wav) |
| Прихожая | ключница | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-key-cabinet.png) | [Kore](../../ToddlerLock/Resources/Speech/home-key-cabinet.wav) |
| Прихожая | коврик у двери | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-doormat.png) | [Kore](../../ToddlerLock/Resources/Speech/home-doormat.wav) |
| Комната | календарь | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-calendar.png) | [Kore](../../ToddlerLock/Resources/Speech/home-calendar.wav) |
| Комната | глобус | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-globe.png) | [Kore](../../ToddlerLock/Resources/Speech/home-globe.wav) |
| Комната | фоторамка | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-photo-frame.png) | [Kore](../../ToddlerLock/Resources/Speech/home-photo-frame.wav) |
| Комната | магнитная доска | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-magnetic-board.png) | [Kore](../../ToddlerLock/Resources/Speech/home-magnetic-board.wav) |
| Комната | пенал | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-pencil-case.png) | [Kore](../../ToddlerLock/Resources/Speech/home-pencil-case.wav) |
| Комната | ластик | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-eraser.png) | [Kore](../../ToddlerLock/Resources/Speech/home-eraser.wav) |
| Комната | точилка | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-pencil-sharpener.png) | [Kore](../../ToddlerLock/Resources/Speech/home-pencil-sharpener.wav) |
| Комната | линейка | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-ruler.png) | [Kore](../../ToddlerLock/Resources/Speech/home-ruler.wav) |
| Комната | пазл | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-jigsaw-puzzle.png) | [Kore](../../ToddlerLock/Resources/Speech/home-jigsaw-puzzle.wav) |
| Комната | копилка | [PNG](../../ToddlerLock/Resources/Pictures/Household/home-piggy-bank.png) | [Kore](../../ToddlerLock/Resources/Speech/home-piggy-bank.wav) |
