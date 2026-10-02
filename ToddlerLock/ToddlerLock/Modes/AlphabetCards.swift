import Foundation

/// Three familiar examples per letter; signs and Ы are highlighted inside words.
enum AlphabetCards {
    static let examples: [[StorybookPicture]] = [
        // А
        [
            .init(name: "арбуз", assetName: "alphabet-watermelon"),
            .init(name: "автобус", assetName: "transport-bus"),
            .init(name: "аист", assetName: "animal-stork"),
        ],
        // Б
        [
            .init(name: "бабочка", assetName: "animal-butterfly"),
            .init(name: "белка", assetName: "animal-squirrel"),
            .init(name: "банан", assetName: "alphabet-banana"),
        ],
        // В
        [
            .init(name: "ванна", assetName: "home-bathtub"),
            .init(name: "воробей", assetName: "animal-sparrow"),
            .init(name: "велосипед", assetName: "transport-bicycle"),
        ],
        // Г
        [
            .init(name: "гусь", assetName: "animal-goose"),
            .init(name: "гриб", assetName: "alphabet-mushroom"),
            .init(name: "грузовик", assetName: "transport-truck"),
        ],
        // Д
        [
            .init(name: "дом", assetName: "alphabet-house"),
            .init(name: "дятел", assetName: "animal-woodpecker"),
            .init(name: "диван", assetName: "alphabet-sofa"),
        ],
        // Е
        [
            .init(name: "енот", assetName: "animal-raccoon"),
            .init(name: "ель", assetName: "alphabet-spruce"),
            .init(name: "ежевика", assetName: "alphabet-blackberry"),
        ],
        // Ё
        [
            .init(name: "ёжик", assetName: "animal-hedgehog"),
            .init(name: "ёлка", assetName: "alphabet-christmas-tree"),
            .init(name: "ёрш", assetName: "alphabet-ruffe"),
        ],
        // Ж
        [
            .init(name: "жираф", assetName: "animal-giraffe"),
            .init(name: "жук", assetName: "animal-beetle"),
            .init(name: "жаба", assetName: "alphabet-toad"),
        ],
        // З
        [
            .init(name: "заяц", assetName: "animal-hare"),
            .init(name: "зебра", assetName: "animal-zebra"),
            .init(name: "зонтик", assetName: "home-umbrella"),
        ],
        // И
        [
            .init(name: "индюк", assetName: "animal-turkey"),
            .init(name: "игрушка", assetName: "alphabet-toy"),
            .init(name: "изюм", assetName: "alphabet-raisins"),
        ],
        // Й
        [
            .init(name: "йогурт", assetName: "alphabet-yogurt"),
            .init(name: "чайник", assetName: "home-kettle"),
            .init(name: "трамвай", assetName: "transport-tram"),
        ],
        // К
        [
            .init(name: "кот", assetName: "animal-cat"),
            .init(name: "корова", assetName: "animal-cow"),
            .init(name: "корабль", assetName: "transport-ship"),
        ],
        // Л
        [
            .init(name: "лиса", assetName: "animal-fox"),
            .init(name: "лев", assetName: "animal-lion"),
            .init(name: "ложка", assetName: "home-spoon"),
        ],
        // М
        [
            .init(name: "мыло", assetName: "home-soap"),
            .init(name: "машина", assetName: "transport-car"),
            .init(name: "медведь", assetName: "animal-bear"),
        ],
        // Н
        [
            .init(name: "носорог", assetName: "animal-rhinoceros"),
            .init(name: "ножницы", assetName: "alphabet-scissors"),
            .init(name: "носки", assetName: "alphabet-socks"),
        ],
        // О
        [
            .init(name: "осёл", assetName: "animal-donkey"),
            .init(name: "овечка", assetName: "animal-sheep"),
            .init(name: "огурец", assetName: "alphabet-cucumber"),
        ],
        // П
        [
            .init(name: "попугай", assetName: "animal-parrot"),
            .init(name: "поезд", assetName: "transport-train"),
            .init(name: "подушка", assetName: "home-pillow"),
        ],
        // Р
        [
            .init(name: "рыба", assetName: "animal-goldfish"),
            .init(name: "ракета", assetName: "transport-rocket"),
            .init(name: "расчёска", assetName: "home-comb"),
        ],
        // С
        [
            .init(name: "слон", assetName: "animal-elephant"),
            .init(name: "собака", assetName: "animal-dog"),
            .init(name: "самокат", assetName: "transport-scooter"),
        ],
        // Т
        [
            .init(name: "трактор", assetName: "transport-tractor"),
            .init(name: "тигр", assetName: "animal-tiger"),
            .init(name: "тарелка", assetName: "home-plate"),
        ],
        // У
        [
            .init(name: "утка", assetName: "animal-duck"),
            .init(name: "улитка", assetName: "animal-snail"),
            .init(name: "утюг", assetName: "alphabet-iron"),
        ],
        // Ф
        [
            .init(name: "фламинго", assetName: "animal-flamingo"),
            .init(name: "фургон", assetName: "transport-delivery-van"),
            .init(name: "фонарь", assetName: "alphabet-lantern"),
        ],
        // Х
        [
            .init(name: "хомяк", assetName: "animal-hamster"),
            .init(name: "хлеб", assetName: "alphabet-bread"),
            .init(name: "холодильник", assetName: "home-fridge"),
        ],
        // Ц
        [
            .init(name: "цыплёнок", assetName: "alphabet-chick"),
            .init(name: "цветок", assetName: "alphabet-flower"),
            .init(name: "цирк", assetName: "alphabet-circus"),
        ],
        // Ч
        [
            .init(name: "чашка", assetName: "home-cup"),
            .init(name: "часы", assetName: "home-clock"),
            .init(name: "черепаха", assetName: "animal-turtle"),
        ],
        // Ш
        [
            .init(name: "шапка", assetName: "home-hat"),
            .init(name: "шарф", assetName: "home-scarf"),
            .init(name: "шкаф", assetName: "alphabet-wardrobe"),
        ],
        // Щ
        [
            .init(name: "щука", assetName: "animal-pike"),
            .init(name: "щётка", assetName: "alphabet-brush"),
            .init(name: "щенок", assetName: "alphabet-puppy"),
        ],
        // Ъ
        [
            .init(name: "подъезд", assetName: "alphabet-entrance"),
            .init(name: "объявление", assetName: "alphabet-notice"),
            .init(name: "подъёмный кран", assetName: "transport-crane-truck"),
        ],
        // Ы
        [
            .init(name: "сыр", assetName: "alphabet-cheese"),
            .init(name: "мышка", assetName: "animal-mouse"),
            .init(name: "рыба", assetName: "animal-goldfish"),
        ],
        // Ь
        [
            .init(name: "конь", assetName: "animal-horse"),
            .init(name: "дверь", assetName: "home-door"),
            .init(name: "тюлень", assetName: "animal-seal"),
        ],
        // Э
        [
            .init(name: "экскаватор", assetName: "transport-excavator"),
            .init(name: "экран", assetName: "alphabet-screen"),
            .init(name: "эскимо", assetName: "alphabet-ice-cream"),
        ],
        // Ю
        [
            .init(name: "юла", assetName: "alphabet-spinning-top"),
            .init(name: "юбка", assetName: "alphabet-skirt"),
            .init(name: "юрта", assetName: "alphabet-yurt"),
        ],
        // Я
        [
            .init(name: "яблоко", assetName: "alphabet-apple"),
            .init(name: "якорь", assetName: "alphabet-anchor"),
            .init(name: "ягоды", assetName: "alphabet-berries"),
        ],
    ]
}
