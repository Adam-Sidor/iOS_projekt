import SwiftUI

struct SzczegolyView: View {
    let postac: Postac
    @State private var jestPowiekszony = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // Zdjęcie
                if let zdjecie = postac.zdjecie {
                    Image(zdjecie)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                    // --- LONG PRESS ---
                                        .scaleEffect(jestPowiekszony ? 1.2 : 1.0) // Jeśli prawda powiększ o 20%, jeśli fałsz wróć do 1.0
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: jestPowiekszony) // Płynne, sprężyste przejście
                                        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
                                            // Ta sekcja wykonuje się OD RAZU, gdy palec dotyka ekranu (pressing = true)
                                            // oraz gdy palec zostaje zabrany (pressing = false)
                                            jestPowiekszony = pressing
                                        }, perform: {
                                            // Ta sekcja wykonuje się TYLKO, gdy użytkownik przytrzyma obrazek przez pełne 0.5 sekundy.
                                            // Możesz zostawić ją pustą, bo zmianę rozmiaru obsługujemy już wyżej!
                                        })
                }

                Text(postac.opis ?? "")
                    .font(.body)
                    .foregroundColor(.secondary)

                // Atrybuty
                if let atrybuty = postac.atrybuty as? Set<Atrybut>, !atrybuty.isEmpty {
                    Divider()
                    Text("Atrybuty")
                        .font(.headline)

                    ForEach(atrybuty.sorted { $0.nazwa ?? "" < $1.nazwa ?? "" }, id: \.self) { atrybut in
                        HStack {
                            Text(atrybut.nazwa ?? "")
                            Spacer()
                            ForEach(0..<3, id: \.self) { i in
                                Image(systemName: i < atrybut.wartosc ? "star.fill" : "star")
                            }
                        }
                    }
                }
            }
            .navigationTitle(postac.nazwa ?? "")
            .padding()
        }
    }
}
