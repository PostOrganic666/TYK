import AppKit
import SpriteKit

enum PictureCollection {
    case animals
    case transport
    case household

    var pictures: [StorybookPicture] {
        switch self {
        case .animals:
            return [
                .init(name: "медведь", assetName: "animal-bear"),
                .init(name: "лиса", assetName: "animal-fox"),
                .init(name: "заяц", assetName: "animal-hare"),
                .init(name: "ёжик", assetName: "animal-hedgehog"),
                .init(name: "кот", assetName: "animal-cat"),
                .init(name: "собака", assetName: "animal-dog"),
                .init(name: "белка", assetName: "animal-squirrel"),
                .init(name: "сова", assetName: "animal-owl"),
                .init(name: "енот", assetName: "animal-raccoon"),
                .init(name: "оленёнок", assetName: "animal-fawn"),
                .init(name: "лягушка", assetName: "animal-frog"),
                .init(name: "утка", assetName: "animal-duck"),
                .init(name: "пингвин", assetName: "animal-penguin"),
                .init(name: "слон", assetName: "animal-elephant"),
                .init(name: "жираф", assetName: "animal-giraffe"),
                .init(name: "лев", assetName: "animal-lion"),
                .init(name: "зебра", assetName: "animal-zebra"),
                .init(name: "обезьяна", assetName: "animal-monkey"),
                .init(name: "корова", assetName: "animal-cow"),
                .init(name: "поросёнок", assetName: "animal-pig"),
                .init(name: "овечка", assetName: "animal-sheep"),
                .init(name: "коза", assetName: "animal-goat"),
                .init(name: "лошадь", assetName: "animal-horse"),
                .init(name: "курица", assetName: "animal-chicken"),
                .init(name: "черепаха", assetName: "animal-turtle"),
                .init(name: "крокодил", assetName: "animal-crocodile"),
                .init(name: "дельфин", assetName: "animal-dolphin"),
                .init(name: "кит", assetName: "animal-whale"),
                .init(name: "тюлень", assetName: "animal-seal"),
                .init(name: "кенгуру", assetName: "animal-kangaroo"),
                .init(name: "бобр", assetName: "animal-beaver"),
                .init(name: "барсук", assetName: "animal-badger"),
                .init(name: "хомяк", assetName: "animal-hamster"),
                .init(name: "мышка", assetName: "animal-mouse"),
                .init(name: "волк", assetName: "animal-wolf"),
                .init(name: "кабан", assetName: "animal-boar"),
                .init(name: "верблюд", assetName: "animal-camel"),
                .init(name: "носорог", assetName: "animal-rhinoceros"),
                .init(name: "бегемот", assetName: "animal-hippopotamus"),
                .init(name: "тигр", assetName: "animal-tiger"),
                .init(name: "леопард", assetName: "animal-leopard"),
                .init(name: "панда", assetName: "animal-panda"),
                .init(name: "коала", assetName: "animal-koala"),
                .init(name: "ленивец", assetName: "animal-sloth"),
                .init(name: "лама", assetName: "animal-llama"),
                .init(name: "альпака", assetName: "animal-alpaca"),
                .init(name: "осёл", assetName: "animal-donkey"),
                .init(name: "бизон", assetName: "animal-bison"),
                .init(name: "павлин", assetName: "animal-peacock"),
                .init(name: "фламинго", assetName: "animal-flamingo"),
                .init(name: "попугай", assetName: "animal-parrot"),
                .init(name: "дятел", assetName: "animal-woodpecker"),
                .init(name: "аист", assetName: "animal-stork"),
                .init(name: "лебедь", assetName: "animal-swan"),
                .init(name: "осьминог", assetName: "animal-octopus"),
                .init(name: "морская звезда", assetName: "animal-starfish"),
                .init(name: "краб", assetName: "animal-crab"),
                .init(name: "морж", assetName: "animal-walrus"),
                .init(name: "акула", assetName: "animal-shark"),
                .init(name: "скат", assetName: "animal-manta-ray"),
                .init(name: "бабочка", assetName: "animal-butterfly"),
                .init(name: "пчела", assetName: "animal-bee"),
                .init(name: "божья коровка", assetName: "animal-ladybug"),
                .init(name: "муравей", assetName: "animal-ant"),
                .init(name: "стрекоза", assetName: "animal-dragonfly"),
                .init(name: "кузнечик", assetName: "animal-grasshopper"),
                .init(name: "жук", assetName: "animal-beetle"),
                .init(name: "гусеница", assetName: "animal-caterpillar"),
                .init(name: "улитка", assetName: "animal-snail"),
                .init(name: "паук", assetName: "animal-spider"),
                .init(name: "воробей", assetName: "animal-sparrow"),
                .init(name: "голубь", assetName: "animal-pigeon"),
                .init(name: "ворона", assetName: "animal-crow"),
                .init(name: "сорока", assetName: "animal-magpie"),
                .init(name: "снегирь", assetName: "animal-bullfinch"),
                .init(name: "синица", assetName: "animal-tit"),
                .init(name: "ласточка", assetName: "animal-swallow"),
                .init(name: "гусь", assetName: "animal-goose"),
                .init(name: "петух", assetName: "animal-rooster"),
                .init(name: "индюк", assetName: "animal-turkey"),
                .init(name: "золотая рыбка", assetName: "animal-goldfish"),
                .init(name: "рыба-клоун", assetName: "animal-clownfish"),
                .init(name: "окунь", assetName: "animal-perch"),
                .init(name: "щука", assetName: "animal-pike"),
                .init(name: "сом", assetName: "animal-catfish"),
                .init(name: "морской конёк", assetName: "animal-seahorse"),
                .init(name: "медуза", assetName: "animal-jellyfish"),
                .init(name: "кролик", assetName: "animal-rabbit"),
                .init(name: "морская свинка", assetName: "animal-guinea-pig"),
                .init(name: "крот", assetName: "animal-mole"),
            ]
        case .transport:
            return [
                .init(name: "трактор", assetName: "transport-tractor"),
                .init(name: "поезд", assetName: "transport-train"),
                .init(name: "автобус", assetName: "transport-bus"),
                .init(name: "экскаватор", assetName: "transport-excavator"),
                .init(name: "самолёт", assetName: "transport-airplane"),
                .init(name: "буксир", assetName: "transport-tugboat"),
                .init(name: "пожарная машина", assetName: "transport-fire-engine"),
                .init(name: "скорая помощь", assetName: "transport-ambulance"),
                .init(name: "полицейская машина", assetName: "transport-police-car"),
                .init(name: "самосвал", assetName: "transport-dump-truck"),
                .init(name: "бетономешалка", assetName: "transport-concrete-mixer"),
                .init(name: "бульдозер", assetName: "transport-bulldozer"),
                .init(name: "автокран", assetName: "transport-crane-truck"),
                .init(name: "мусоровоз", assetName: "transport-garbage-truck"),
                .init(name: "вертолёт", assetName: "transport-helicopter"),
                .init(name: "ракета", assetName: "transport-rocket"),
                .init(name: "велосипед", assetName: "transport-bicycle"),
                .init(name: "мотоцикл", assetName: "transport-motorcycle"),
                .init(name: "трамвай", assetName: "transport-tram"),
                .init(name: "поезд метро", assetName: "transport-subway-train"),
                .init(name: "такси", assetName: "transport-taxi"),
                .init(name: "фургон", assetName: "transport-delivery-van"),
                .init(name: "парусник", assetName: "transport-sailboat"),
                .init(name: "подводная лодка", assetName: "transport-submarine"),
                .init(name: "паром", assetName: "transport-ferry"),
                .init(name: "воздушный шар", assetName: "transport-hot-air-balloon"),
                .init(name: "самокат", assetName: "transport-scooter"),
                .init(name: "снегоход", assetName: "transport-snowmobile"),
                .init(name: "погрузчик", assetName: "transport-forklift"),
                .init(name: "комбайн", assetName: "transport-combine"),
                .init(name: "машина", assetName: "transport-car"),
                .init(name: "грузовик", assetName: "transport-truck"),
                .init(name: "микроавтобус", assetName: "transport-minibus"),
                .init(name: "троллейбус", assetName: "transport-trolleybus"),
                .init(name: "каток", assetName: "transport-road-roller"),
                .init(name: "снегоуборочная машина", assetName: "transport-snowplow"),
                .init(name: "подметальная машина", assetName: "transport-street-sweeper"),
                .init(name: "автовоз", assetName: "transport-car-carrier"),
                .init(name: "автоцистерна", assetName: "transport-tanker"),
                .init(name: "эвакуатор", assetName: "transport-tow-truck"),
                .init(name: "квадроцикл", assetName: "transport-quad-bike"),
                .init(name: "беговел", assetName: "transport-balance-bike"),
                .init(name: "детский самокат", assetName: "transport-kick-scooter"),
                .init(name: "лодка", assetName: "transport-rowboat"),
                .init(name: "катер", assetName: "transport-motorboat"),
                .init(name: "корабль", assetName: "transport-ship"),
                .init(name: "водный мотоцикл", assetName: "transport-jet-ski"),
                .init(name: "дельтаплан", assetName: "transport-hang-glider"),
                .init(name: "дирижабль", assetName: "transport-airship"),
                .init(name: "луноход", assetName: "transport-space-rover"),
            ]
        case .household:
            return [
                // Кухня
                .init(name: "чашка", assetName: "home-cup"),
                .init(name: "тарелка", assetName: "home-plate"),
                .init(name: "миска", assetName: "home-bowl"),
                .init(name: "ложка", assetName: "home-spoon"),
                .init(name: "вилка", assetName: "home-fork"),
                .init(name: "стакан", assetName: "home-glass"),
                .init(name: "бутылочка", assetName: "home-bottle"),
                .init(name: "кастрюля", assetName: "home-pot"),
                .init(name: "сковорода", assetName: "home-pan"),
                .init(name: "чайник", assetName: "home-kettle"),
                .init(name: "кувшин", assetName: "home-jug"),
                .init(name: "дуршлаг", assetName: "home-strainer"),
                .init(name: "разделочная доска", assetName: "home-cutting-board"),
                .init(name: "салфетка", assetName: "home-napkin"),
                .init(name: "слюнявчик", assetName: "home-bib"),
                .init(name: "детский стульчик", assetName: "home-high-chair"),
                .init(name: "холодильник", assetName: "home-fridge"),
                .init(name: "плита", assetName: "home-stove"),
                // Ванная
                .init(name: "ванна", assetName: "home-bathtub"),
                .init(name: "раковина", assetName: "home-sink"),
                .init(name: "кран", assetName: "home-faucet"),
                .init(name: "мыло", assetName: "home-soap"),
                .init(name: "зубная щётка", assetName: "home-toothbrush"),
                .init(name: "зубная паста", assetName: "home-toothpaste"),
                .init(name: "полотенце", assetName: "home-bath-towel"),
                .init(name: "расчёска", assetName: "home-comb"),
                .init(name: "мочалка", assetName: "home-sponge"),
                .init(name: "горшок", assetName: "home-potty"),
                .init(name: "уточка для ванны", assetName: "home-rubber-duck"),
                .init(name: "стиральная машина", assetName: "home-washing-machine"),
                .init(name: "корзина для белья", assetName: "home-laundry-basket"),
                .init(name: "шампунь", assetName: "home-shampoo"),
                // Прихожая
                .init(name: "дверь", assetName: "home-door"),
                .init(name: "ключи", assetName: "home-keys"),
                .init(name: "ботинки", assetName: "home-shoes"),
                .init(name: "тапочки", assetName: "home-slippers"),
                .init(name: "куртка", assetName: "home-coat"),
                .init(name: "шапка", assetName: "home-hat"),
                .init(name: "шарф", assetName: "home-scarf"),
                .init(name: "зонтик", assetName: "home-umbrella"),
                .init(name: "рюкзак", assetName: "home-backpack"),
                .init(name: "коляска", assetName: "home-stroller"),
                // Комната
                .init(name: "стул", assetName: "home-chair"),
                .init(name: "стол", assetName: "home-table"),
                .init(name: "кровать", assetName: "home-bed"),
                .init(name: "подушка", assetName: "home-pillow"),
                .init(name: "одеяло", assetName: "home-blanket"),
                .init(name: "лампа", assetName: "home-lamp"),
                .init(name: "часы", assetName: "home-clock"),
                .init(name: "книга", assetName: "home-book"),
            ]
        }
    }
}

/// A quiet cause-and-effect scene with one recognizable illustration at a time.
final class PictureMode: PlayMode {
    let scene: SKScene
    var spriteScene: SKScene? { scene }
    var contentView: NSView? { nil }

    private let collection: PictureCollection
    private let pictures: [StorybookPicture]
    private let titleNode = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private var pictureNode: SKSpriteNode?
    private var index = 0

    init(size: CGSize, collection: PictureCollection) {
        self.collection = collection
        self.pictures = collection.pictures.shuffled()
        scene = SKScene(size: size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = StorybookPalette.cream

        let colors: (NSColor, NSColor, NSColor)
        switch collection {
        case .animals:
            colors = (StorybookPalette.sky, StorybookPalette.cream, StorybookPalette.sage)
        case .transport:
            colors = (NSColor(calibratedRed: 0.70, green: 0.83, blue: 0.90, alpha: 1),
                      NSColor(calibratedRed: 0.94, green: 0.87, blue: 0.72, alpha: 1),
                      NSColor(calibratedRed: 0.69, green: 0.59, blue: 0.43, alpha: 1))
        case .household:
            colors = (NSColor(calibratedRed: 0.94, green: 0.84, blue: 0.78, alpha: 1),
                      StorybookPalette.cream,
                      NSColor(calibratedRed: 0.73, green: 0.66, blue: 0.55, alpha: 1))
        }
        StorybookBackdrop.add(to: scene, top: colors.0, bottom: colors.1, ground: colors.2)

        titleNode.fontColor = StorybookPalette.ink
        titleNode.fontSize = max(28, min(size.width, size.height) * 0.055)
        titleNode.position = CGPoint(x: size.width / 2, y: size.height * 0.10)
        titleNode.zPosition = 20
        scene.addChild(titleNode)
        show(pictures[0], speaks: false)
    }

    func handleKeyDown(keyCode: UInt16, characters: String?) { advance() }
    func handleKeyUp(keyCode: UInt16) {}
    func handleMouseMove(position: CGPoint) {}
    func handleMouseDragged(position: CGPoint) {}
    func handleMouseDown(position: CGPoint) { advance() }

    func willEnd() {
        RussianSpeech.shared.stop()
    }

    private func advance() {
        index = (index + 1) % pictures.count
        show(pictures[index], speaks: true)
    }

    private func show(_ picture: StorybookPicture, speaks: Bool) {
        if let old = pictureNode {
            old.removeAllActions()
            old.run(.sequence([
                .group([.fadeOut(withDuration: 0.14), .scale(to: 0.92, duration: 0.14)]),
                .removeFromParent(),
            ]))
        }

        let node = SKSpriteNode(texture: picture.texture)
        let side = min(scene.size.width * 0.58, scene.size.height * 0.62)
        node.size = CGSize(width: side, height: side)
        node.position = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.53)
        node.alpha = 0
        node.setScale(0.88)
        node.zPosition = 10
        scene.addChild(node)
        pictureNode = node

        let arrival = SKAction.group([
            .fadeIn(withDuration: 0.22),
            .scale(to: 1.04, duration: 0.22),
        ])
        node.run(.sequence([arrival, .scale(to: 1.0, duration: 0.16)]))

        titleNode.text = picture.name
        titleNode.alpha = 0
        titleNode.run(.fadeIn(withDuration: 0.24))

        guard speaks else { return }
        RussianSpeech.shared.speak(picture.name)
        if SettingsStore.shared.soundEnabled {
            SampledInstrument.shared.volume = Float(SettingsStore.shared.maxVolume) * 0.48
            SampledInstrument.shared.play(scaleIndex: index, velocity: 48)
        }
    }
}
