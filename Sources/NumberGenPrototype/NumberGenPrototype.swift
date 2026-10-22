import SwiftUI

enum PlateRarity: String, Codable, CaseIterable {
    case common = "Обычный"
    case uncommon = "Необычный"
    case rare = "Редкий"
    case epic = "Эпический"
    case legendary = "Легендарный"

    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }

    var reward: Int {
        switch self {
        case .common: return 5
        case .uncommon: return 12
        case .rare: return 30
        case .epic: return 80
        case .legendary: return 250
        }
    }
}

struct Plate: Identifiable, Codable, Hashable {
    var id = UUID()
    var value: String
    var region: String
    var rarity: PlateRarity
    var date = Date()
}

@MainActor
final class GameModel: ObservableObject {
    @Published var coins: Int = 100
    @Published var upgradeLevel: Int = 0
    @Published var collection: [Plate] = [] {
        didSet { save() }
    }

    private let saveKey = "numbergen.prototype.save.v1"

    init() { load() }

    var generationCost: Int { max(5, 15 - upgradeLevel) }

    func generate() -> Plate? {
        guard coins >= generationCost else { return nil }
        coins -= generationCost
        let roll = Int.random(in: 1...1000)
        let rarity: PlateRarity
        switch roll {
        case 1...5: rarity = .legendary
        case 6...35: rarity = .epic
        case 36...150: rarity = .rare
        case 151...400: rarity = .uncommon
        default: rarity = .common
        }
        let letters = Array("АВЕКМНОРСТУХ")
        let nums = (0..<3).map { _ in String(Int.random(in: 0...9)) }.joined()
        let chars = (0..<3).map { _ in String(letters.randomElement()!) }.joined()
        let plate = Plate(value: "\(chars)\(nums)", region: ["38", " Ирк", "77", "99", "125"].randomElement()!.trimmingCharacters(in: .whitespaces), rarity: rarity)
        collection.insert(plate, at: 0)
        coins += rarity.reward
        return plate
    }

    func buyUpgrade() {
        let cost = upgradeCost
        guard coins >= cost else { return }
        coins -= cost
        upgradeLevel += 1
        save()
    }

    var upgradeCost: Int { 100 * (upgradeLevel + 1) }

    private func save() {
        let data = try? JSONEncoder().encode(collection)
        UserDefaults.standard.set(data, forKey: "numbergen.prototype.collection")
        UserDefaults.standard.set(coins, forKey: "numbergen.prototype.coins")
        UserDefaults.standard.set(upgradeLevel, forKey: "numbergen.prototype.upgrade")
    }

    private func load() {
        coins = UserDefaults.standard.object(forKey: "numbergen.prototype.coins") as? Int ?? 100
        upgradeLevel = UserDefaults.standard.object(forKey: "numbergen.prototype.upgrade") as? Int ?? 0
        if let data = UserDefaults.standard.data(forKey: "numbergen.prototype.collection"),
           let decoded = try? JSONDecoder().decode([Plate].self, from: data) {
            collection = decoded
        }
    }
}

struct ContentView: View {
    @StateObject private var game = GameModel()
    @State private var latest: Plate?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            garage.tabItem { Label("Гараж", systemImage: "car.side") }.tag(0)
            collectionView.tabItem { Label("Коллекция", systemImage: "rectangle.stack") }.tag(1)
            upgrades.tabItem { Label("Улучшения", systemImage: "arrow.up.circle") }.tag(2)
        }
        .preferredColorScheme(.dark)
        .tint(.orange)
    }

    private var garage: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        Label("\(game.coins) монет", systemImage: "circle.hexagongrid.fill")
                            .font(.headline)
                        Spacer()
                        Text("Ур. \(game.upgradeLevel + 1)")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(.white.opacity(0.1), in: Capsule())
                    }
                    plateCard(latest)
                    Button {
                        latest = game.generate()
                    } label: {
                        VStack(spacing: 4) {
                            Text("СГЕНЕРИРОВАТЬ НОМЕР").font(.headline.bold())
                            Text("Цена: \(game.generationCost) монет").font(.caption)
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(.orange, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.black)
                    }
                    .disabled(game.coins < game.generationCost)
                    .opacity(game.coins < game.generationCost ? 0.5 : 1)
                    Text("Каждый номер сохраняется в коллекции автоматически.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding()
            }
            .navigationTitle("NumberGen")
        }
    }

    private func plateCard(_ plate: Plate?) -> some View {
        VStack(spacing: 12) {
            Text(plate == nil ? "ТВОЙ НОМЕР" : "НОВЫЙ НОМЕР")
                .font(.caption.bold()).tracking(2).foregroundStyle(.secondary)
            Text(plate?.value ?? "А000АА")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .minimumScaleFactor(0.7).lineLimit(1)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(.white, in: RoundedRectangle(cornerRadius: 9))
                .foregroundStyle(.black)
                .overlay(alignment: .trailing) {
                    Text(plate?.region ?? "38")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.trailing, 8)
                        .offset(y: 18)
                }
            if let plate {
                Text("\(plate.rarity.rawValue) • +\(plate.rarity.reward) монет")
                    .font(.subheadline.bold()).foregroundStyle(plate.rarity.color)
            } else {
                Text("Нажми кнопку, чтобы получить первый номер")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 22))
    }

    private var collectionView: some View {
        NavigationStack {
            Group {
                if game.collection.isEmpty {
                    ContentUnavailableView("Коллекция пуста", systemImage: "rectangle.stack", description: Text("Сгенерируй первый номер в гараже."))
                } else {
                    List(game.collection) { plate in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.white).frame(width: 112, height: 42)
                                .overlay(Text(plate.value).font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(.black))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plate.rarity.rawValue).font(.headline).foregroundStyle(plate.rarity.color)
                                Text("Регион \(plate.region)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("+\(plate.rarity.reward)").font(.caption.bold())
                        }.listRowBackground(Color.white.opacity(0.05))
                    }.listStyle(.plain)
                }
            }.navigationTitle("Коллекция · \(game.collection.count)")
        }
    }

    private var upgrades: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "bolt.fill").font(.system(size: 54)).foregroundStyle(.orange)
                Text("Ускорение генератора").font(.title2.bold())
                Text("Уровень \(game.upgradeLevel)")
                Text("Следующее улучшение снижает стоимость генерации.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)
                Button {
                    game.buyUpgrade()
                } label: {
                    Text("Улучшить за \(game.upgradeCost) монет")
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(.orange, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.black)
                }.disabled(game.coins < game.upgradeCost)
                Text("Баланс: \(game.coins) монет").font(.footnote).foregroundStyle(.secondary)
                Spacer()
            }.padding().navigationTitle("Улучшения")
        }
    }
}

@main
struct NumberGenPrototypeApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
