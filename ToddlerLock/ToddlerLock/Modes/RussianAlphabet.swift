import Foundation

struct RussianLetter {
    let glyph: String
    let spokenName: String
}

enum RussianAlphabet {
    static let letters: [RussianLetter] = [
        .init(glyph: "А", spokenName: "а"),
        .init(glyph: "Б", spokenName: "бэ"),
        .init(glyph: "В", spokenName: "вэ"),
        .init(glyph: "Г", spokenName: "гэ"),
        .init(glyph: "Д", spokenName: "дэ"),
        .init(glyph: "Е", spokenName: "е"),
        .init(glyph: "Ё", spokenName: "ё"),
        .init(glyph: "Ж", spokenName: "жэ"),
        .init(glyph: "З", spokenName: "зэ"),
        .init(glyph: "И", spokenName: "и"),
        .init(glyph: "Й", spokenName: "и краткое"),
        .init(glyph: "К", spokenName: "ка"),
        .init(glyph: "Л", spokenName: "эль"),
        .init(glyph: "М", spokenName: "эм"),
        .init(glyph: "Н", spokenName: "эн"),
        .init(glyph: "О", spokenName: "о"),
        .init(glyph: "П", spokenName: "пэ"),
        .init(glyph: "Р", spokenName: "эр"),
        .init(glyph: "С", spokenName: "эс"),
        .init(glyph: "Т", spokenName: "тэ"),
        .init(glyph: "У", spokenName: "у"),
        .init(glyph: "Ф", spokenName: "эф"),
        .init(glyph: "Х", spokenName: "ха"),
        .init(glyph: "Ц", spokenName: "цэ"),
        .init(glyph: "Ч", spokenName: "чэ"),
        .init(glyph: "Ш", spokenName: "ша"),
        .init(glyph: "Щ", spokenName: "ща"),
        .init(glyph: "Ъ", spokenName: "твёрдый знак"),
        .init(glyph: "Ы", spokenName: "ы"),
        .init(glyph: "Ь", spokenName: "мягкий знак"),
        .init(glyph: "Э", spokenName: "э"),
        .init(glyph: "Ю", spokenName: "ю"),
        .init(glyph: "Я", spokenName: "я"),
    ]

    static func letter(for keyCode: UInt16, characters: String?) -> RussianLetter {
        if let character = characters?.uppercased().first.map(String.init),
           let match = letters.first(where: { $0.glyph == character }) {
            return match
        }
        return letters[Int(keyCode) % letters.count]
    }
}

