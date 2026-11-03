import Foundation

/// Six familiar examples per letter; each visit reveals three in shuffled order.
enum AlphabetCards {
    static let examples: [[StorybookPicture]] = [
        // А
        [
            .init(name: "арбуз", assetName: "alphabet-watermelon"),
            .init(name: "автобус", assetName: "transport-bus"),
            .init(name: "аист", assetName: "animal-stork"),
            .init(name: "акула", assetName: "animal-shark"),
            .init(name: "альпака", assetName: "animal-alpaca"),
            .init(name: "автоцистерна", assetName: "transport-tanker"),
        ],
        // Б
        [
            .init(name: "бабочка", assetName: "animal-butterfly"),
            .init(name: "белка", assetName: "animal-squirrel"),
            .init(name: "банан", assetName: "alphabet-banana"),
            .init(name: "бобр", assetName: "animal-beaver"),
            .init(name: "барсук", assetName: "animal-badger"),
            .init(name: "бегемот", assetName: "animal-hippopotamus"),
        ],
        // В
        [
            .init(name: "ванна", assetName: "home-bathtub"),
            .init(name: "воробей", assetName: "animal-sparrow"),
            .init(name: "велосипед", assetName: "transport-bicycle"),
            .init(name: "волк", assetName: "animal-wolf"),
            .init(name: "верблюд", assetName: "animal-camel"),
            .init(name: "ворона", assetName: "animal-crow"),
        ],
        // Г
        [
            .init(name: "гусь", assetName: "animal-goose"),
            .init(name: "гриб", assetName: "alphabet-mushroom"),
            .init(name: "грузовик", assetName: "transport-truck"),
            .init(name: "голубь", assetName: "animal-pigeon"),
            .init(name: "гусеница", assetName: "animal-caterpillar"),
            .init(name: "горшок", assetName: "home-potty"),
        ],
        // Д
        [
            .init(name: "дом", assetName: "alphabet-house"),
            .init(name: "дятел", assetName: "animal-woodpecker"),
            .init(name: "диван", assetName: "alphabet-sofa"),
            .init(name: "дельфин", assetName: "animal-dolphin"),
            .init(name: "дирижабль", assetName: "transport-airship"),
            .init(name: "душ", assetName: "home-shower-head"),
        ],
        // Е
        [
            .init(name: "енот", assetName: "animal-raccoon"),
            .init(name: "ель", assetName: "alphabet-spruce"),
            .init(name: "ежевика", assetName: "alphabet-blackberry"),
            .init(name: "единорог", assetName: "alphabet-unicorn"),
            .init(name: "ехидна", assetName: "alphabet-echidna"),
            .init(name: "еда", assetName: "alphabet-food"),
        ],
        // Ё
        [
            .init(name: "ёжик", assetName: "animal-hedgehog"),
            .init(name: "ёлка", assetName: "alphabet-christmas-tree"),
            .init(name: "ёрш", assetName: "alphabet-ruffe"),
            .init(name: "мёд", assetName: "alphabet-honey"),
            .init(name: "свёкла", assetName: "alphabet-beetroot"),
            .init(name: "самолёт", assetName: "transport-airplane"),
        ],
        // Ж
        [
            .init(name: "жираф", assetName: "animal-giraffe"),
            .init(name: "жук", assetName: "animal-beetle"),
            .init(name: "жаба", assetName: "alphabet-toad"),
            .init(name: "журавль", assetName: "animal-crane"),
            .init(name: "жук-олень", assetName: "animal-stag-beetle"),
            .init(name: "жилет", assetName: "alphabet-vest"),
        ],
        // З
        [
            .init(name: "заяц", assetName: "animal-hare"),
            .init(name: "зебра", assetName: "animal-zebra"),
            .init(name: "зонтик", assetName: "home-umbrella"),
            .init(name: "зеркало", assetName: "home-mirror"),
            .init(name: "зимородок", assetName: "animal-kingfisher"),
            .init(name: "зарянка", assetName: "animal-robin"),
        ],
        // И
        [
            .init(name: "индюк", assetName: "animal-turkey"),
            .init(name: "игрушка", assetName: "alphabet-toy"),
            .init(name: "изюм", assetName: "alphabet-raisins"),
            .init(name: "игла", assetName: "alphabet-needle"),
            .init(name: "ирис", assetName: "alphabet-iris"),
            .init(name: "иволга", assetName: "alphabet-oriole"),
        ],
        // Й
        [
            .init(name: "йогурт", assetName: "alphabet-yogurt"),
            .init(name: "чайник", assetName: "home-kettle"),
            .init(name: "трамвай", assetName: "transport-tram"),
            .init(name: "канарейка", assetName: "animal-canary"),
            .init(name: "попугай", assetName: "animal-parrot"),
            .init(name: "воробей", assetName: "animal-sparrow"),
        ],
        // К
        [
            .init(name: "кот", assetName: "animal-cat"),
            .init(name: "корова", assetName: "animal-cow"),
            .init(name: "корабль", assetName: "transport-ship"),
            .init(name: "кит", assetName: "animal-whale"),
            .init(name: "коза", assetName: "animal-goat"),
            .init(name: "кролик", assetName: "animal-rabbit"),
        ],
        // Л
        [
            .init(name: "лиса", assetName: "animal-fox"),
            .init(name: "лев", assetName: "animal-lion"),
            .init(name: "ложка", assetName: "home-spoon"),
            .init(name: "лось", assetName: "animal-moose"),
            .init(name: "лама", assetName: "animal-llama"),
            .init(name: "лягушка", assetName: "animal-frog"),
        ],
        // М
        [
            .init(name: "мыло", assetName: "home-soap"),
            .init(name: "машина", assetName: "transport-car"),
            .init(name: "медведь", assetName: "animal-bear"),
            .init(name: "муравей", assetName: "animal-ant"),
            .init(name: "морж", assetName: "animal-walrus"),
            .init(name: "медуза", assetName: "animal-jellyfish"),
        ],
        // Н
        [
            .init(name: "носорог", assetName: "animal-rhinoceros"),
            .init(name: "ножницы", assetName: "alphabet-scissors"),
            .init(name: "носки", assetName: "alphabet-socks"),
            .init(name: "ноутбук", assetName: "home-laptop"),
            .init(name: "наушники", assetName: "alphabet-headphones"),
            .init(name: "нитки", assetName: "alphabet-thread"),
        ],
        // О
        [
            .init(name: "осёл", assetName: "animal-donkey"),
            .init(name: "овечка", assetName: "animal-sheep"),
            .init(name: "огурец", assetName: "alphabet-cucumber"),
            .init(name: "осьминог", assetName: "animal-octopus"),
            .init(name: "орёл", assetName: "animal-eagle"),
            .init(name: "обезьяна", assetName: "animal-monkey"),
        ],
        // П
        [
            .init(name: "попугай", assetName: "animal-parrot"),
            .init(name: "поезд", assetName: "transport-train"),
            .init(name: "подушка", assetName: "home-pillow"),
            .init(name: "петух", assetName: "animal-rooster"),
            .init(name: "пингвин", assetName: "animal-penguin"),
            .init(name: "паук", assetName: "animal-spider"),
        ],
        // Р
        [
            .init(name: "рыба", assetName: "animal-goldfish"),
            .init(name: "ракета", assetName: "transport-rocket"),
            .init(name: "расчёска", assetName: "home-comb"),
            .init(name: "рак", assetName: "animal-crayfish"),
            .init(name: "рысь", assetName: "animal-lynx"),
            .init(name: "раковина", assetName: "home-sink"),
        ],
        // С
        [
            .init(name: "слон", assetName: "animal-elephant"),
            .init(name: "собака", assetName: "animal-dog"),
            .init(name: "самокат", assetName: "transport-scooter"),
            .init(name: "сова", assetName: "animal-owl"),
            .init(name: "сорока", assetName: "animal-magpie"),
            .init(name: "стакан", assetName: "home-glass"),
        ],
        // Т
        [
            .init(name: "трактор", assetName: "transport-tractor"),
            .init(name: "тигр", assetName: "animal-tiger"),
            .init(name: "тарелка", assetName: "home-plate"),
            .init(name: "такси", assetName: "transport-taxi"),
            .init(name: "термос", assetName: "home-thermos"),
            .init(name: "тетрадь", assetName: "home-notebook"),
        ],
        // У
        [
            .init(name: "утка", assetName: "animal-duck"),
            .init(name: "улитка", assetName: "animal-snail"),
            .init(name: "утюг", assetName: "alphabet-iron"),
            .init(name: "удод", assetName: "animal-hoopoe"),
            .init(name: "утконос", assetName: "animal-platypus"),
            .init(name: "унитаз", assetName: "home-toilet"),
        ],
        // Ф
        [
            .init(name: "фламинго", assetName: "animal-flamingo"),
            .init(name: "фургон", assetName: "transport-delivery-van"),
            .init(name: "фонарь", assetName: "alphabet-lantern"),
            .init(name: "фартук", assetName: "home-apron"),
            .init(name: "фен", assetName: "home-hair-dryer"),
            .init(name: "футболка", assetName: "home-tshirt"),
        ],
        // Х
        [
            .init(name: "хомяк", assetName: "animal-hamster"),
            .init(name: "хлеб", assetName: "alphabet-bread"),
            .init(name: "холодильник", assetName: "home-fridge"),
            .init(name: "халат", assetName: "home-bathrobe"),
            .init(name: "хорёк", assetName: "animal-ferret"),
            .init(name: "хлебница", assetName: "home-bread-box"),
        ],
        // Ц
        [
            .init(name: "цыплёнок", assetName: "alphabet-chick"),
            .init(name: "цветок", assetName: "alphabet-flower"),
            .init(name: "цирк", assetName: "alphabet-circus"),
            .init(name: "цапля", assetName: "animal-heron"),
            .init(name: "цепочка", assetName: "alphabet-chain"),
            .init(name: "цукини", assetName: "alphabet-zucchini"),
        ],
        // Ч
        [
            .init(name: "чашка", assetName: "home-cup"),
            .init(name: "часы", assetName: "home-clock"),
            .init(name: "черепаха", assetName: "animal-turtle"),
            .init(name: "чайник", assetName: "home-kettle"),
            .init(name: "чемодан", assetName: "home-suitcase"),
            .init(name: "черпак", assetName: "home-ladle"),
        ],
        // Ш
        [
            .init(name: "шапка", assetName: "home-hat"),
            .init(name: "шарф", assetName: "home-scarf"),
            .init(name: "шкаф", assetName: "alphabet-wardrobe"),
            .init(name: "шмель", assetName: "animal-bumblebee"),
            .init(name: "шиншилла", assetName: "animal-chinchilla"),
            .init(name: "шторы", assetName: "home-curtains"),
        ],
        // Щ
        [
            .init(name: "щука", assetName: "animal-pike"),
            .init(name: "щётка", assetName: "alphabet-brush"),
            .init(name: "щенок", assetName: "alphabet-puppy"),
            .init(name: "прищепка", assetName: "home-clothespin"),
            .init(name: "плащ", assetName: "alphabet-raincoat"),
            .init(name: "щётка для волос", assetName: "home-hairbrush"),
        ],
        // Ъ
        [
            .init(name: "подъезд", assetName: "alphabet-entrance"),
            .init(name: "объявление", assetName: "alphabet-notice"),
            .init(name: "подъёмный кран", assetName: "transport-crane-truck"),
            .init(name: "съёмка", assetName: "alphabet-photography"),
            .init(name: "объятия", assetName: "alphabet-hug"),
            .init(name: "съедобный гриб", assetName: "alphabet-mushroom"),
        ],
        // Ы
        [
            .init(name: "сыр", assetName: "alphabet-cheese"),
            .init(name: "мышка", assetName: "animal-mouse"),
            .init(name: "рыба", assetName: "animal-goldfish"),
            .init(name: "выдра", assetName: "animal-otter"),
            .init(name: "мыло", assetName: "home-soap"),
            .init(name: "тыква", assetName: "alphabet-pumpkin"),
        ],
        // Ь
        [
            .init(name: "конь", assetName: "animal-horse"),
            .init(name: "дверь", assetName: "home-door"),
            .init(name: "тюлень", assetName: "animal-seal"),
            .init(name: "лось", assetName: "animal-moose"),
            .init(name: "северный олень", assetName: "animal-reindeer"),
            .init(name: "шмель", assetName: "animal-bumblebee"),
        ],
        // Э
        [
            .init(name: "экскаватор", assetName: "transport-excavator"),
            .init(name: "экран", assetName: "alphabet-screen"),
            .init(name: "эскимо", assetName: "alphabet-ice-cream"),
            .init(name: "эму", assetName: "alphabet-emu"),
            .init(name: "эвакуатор", assetName: "transport-tow-truck"),
            .init(name: "электричка", assetName: "transport-subway-train"),
        ],
        // Ю
        [
            .init(name: "юла", assetName: "alphabet-spinning-top"),
            .init(name: "юбка", assetName: "alphabet-skirt"),
            .init(name: "юрта", assetName: "alphabet-yurt"),
            .init(name: "изюм", assetName: "alphabet-raisins"),
            .init(name: "люстра", assetName: "alphabet-chandelier"),
            .init(name: "верблюд", assetName: "animal-camel"),
        ],
        // Я
        [
            .init(name: "яблоко", assetName: "alphabet-apple"),
            .init(name: "якорь", assetName: "alphabet-anchor"),
            .init(name: "ягоды", assetName: "alphabet-berries"),
            .init(name: "як", assetName: "animal-yak"),
            .init(name: "ящерица", assetName: "alphabet-lizard"),
            .init(name: "ящик", assetName: "alphabet-box"),
        ],
    ]
}
