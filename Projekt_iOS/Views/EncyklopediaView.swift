import SwiftUI
import CoreData

struct EncyklopediaView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        entity: Postac.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Postac.nazwa, ascending: true)]
    ) var postacie: FetchedResults<Postac>
    
    // Jedna zmienna stanu do otwierania widoku szczegółów
        @State private var wylosowanaPostac: Postac?

    var body: some View {
        NavigationStack {
            VStack{
                Image("wszystkie")
                    .resizable()
                    .scaledToFit()
                // --- OTO NASZ DRUGI GEST (SWIPE / DRAG) ---
                    .gesture(
                        DragGesture(minimumDistance: 30, coordinateSpace: .local)
                            .onEnded { value in
                                // Sprawdzamy, czy ruch palca (lub myszki) był poziomy i wyraźny
                                if abs(value.translation.width) > 50 {
                                    if !postacie.isEmpty {
                                        // Losujemy postać i przypisujemy do zmiennej – to automatycznie otworzy widok
                                        wylosowanaPostac = postacie.randomElement()
                                    }
                                }
                            }
                    )
                if postacie.isEmpty {
                    Text("Brak postaci!")
                } else {
                    List(postacie, id: \.self) { postac in
                        // Uproszczony NavigationLink dla NavigationStack
                        NavigationLink(postac.nazwa ?? "Brak nazwy", value: postac)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Wybierz postać")
            
            // Obsługa kliknięcia w postać z listy
            .navigationDestination(for: Postac.self) { postac in
                SzczegolyView(postac: postac)
            }
            // Obsługa otwarcia po wykonaniu gestu przesunięcia (gdy wylosowanaPostac nie jest nil)
            .navigationDestination(item: $wylosowanaPostac) { postac in
                SzczegolyView(postac: postac)
            }
        }
    }
}

#Preview {
    EncyklopediaView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
