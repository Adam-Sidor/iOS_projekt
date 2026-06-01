import SwiftUI
import CoreData

struct PorownywarkaView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        entity: Postac.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Postac.nazwa, ascending: true)]
    ) var postacie: FetchedResults<Postac>

    @State private var postac1: Postac?
    @State private var postac2: Postac?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                // Pickery
                HStack(spacing: 12) {
                    Picker("Postać 1", selection: $postac1) {
                        Text("Wybierz").tag(Optional<Postac>(nil))
                        ForEach(postacie, id: \.self) { p in
                            Text(p.nazwa ?? "").tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.secondary)
                        .font(.title2) // Powiększyłem odrobinę ikonę, żeby łatwiej było w nią kliknąć
                        .padding(.horizontal, 4)
                        
                        // Obsługa gestu podwójnego tapnięcia
                        .onTapGesture(count: 2) {
                            // withAnimation sprawi, że tabela zamiany płynnie zniknie
                            withAnimation(.easeInOut) {
                                postac1 = nil
                                postac2 = nil
                            }
                        }

                    Picker("Postać 2", selection: $postac2) {
                        Text("Wybierz").tag(Optional<Postac>(nil))
                        ForEach(postacie, id: \.self) { p in
                            Text(p.nazwa ?? "").tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding()

                // Tabela
                if postac1 != nil && postac2 != nil {
                    // Nagłówek
                    HStack {
                        Text("Atrybut")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(postac1?.nazwa ?? "-")
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(postac2?.nazwa ?? "-")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .font(.caption)
                    .bold()
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))

                    Divider()

                    // Wiersze
                    let wszystkieAtrybuty = atrybutySuma()
                    if wszystkieAtrybuty.isEmpty {
                        Spacer()
                        Text("Brak wspólnych atrybutów")
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        List(wszystkieAtrybuty, id: \.self) { nazwa in
                            HStack {
                                Text(nazwa)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                gwiazdki(postac: postac1, atrybut: nazwa)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                gwiazdki(postac: postac2, atrybut: nazwa)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .listStyle(.plain)
                    }
                } else {
                    Spacer()
                    Text("Wybierz postacie do porównania")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .navigationTitle("Porównywarka")
        }
    }

    // Gwiazdki dla danej postaci i atrybutu
    @ViewBuilder
    func gwiazdki(postac: Postac?, atrybut: String) -> some View {
        if let postac = postac,
           let atrybuty = postac.atrybuty as? Set<Atrybut>,
           let znaleziony = atrybuty.first(where: { $0.nazwa == atrybut }) {
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < znaleziony.wartosc ? "star.fill" : "star")
                        .font(.caption)
                }
            }
        } else {
            Text("-").foregroundColor(.secondary)
        }
    }

    func atrybutySuma() -> [String] {
        var nazwy = Set<String>()
        if let p1 = postac1, let a1 = p1.atrybuty as? Set<Atrybut> {
            a1.forEach { nazwy.insert($0.nazwa ?? "") }
        }
        if let p2 = postac2, let a2 = p2.atrybuty as? Set<Atrybut> {
            a2.forEach { nazwy.insert($0.nazwa ?? "") }
        }
        return nazwy.sorted()
    }
}

#Preview {
    PorownywarkaView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
