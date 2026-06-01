import SwiftUI
import CoreData

struct QuizView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        entity: Pytanie.entity(),
        sortDescriptors: []
    ) var pytania: FetchedResults<Pytanie>

    @State private var started = false
    @State private var iloscPytan: Int = 10
    @State private var tekstIlosciPytan: String = "5"
    @State private var bladWalidacji: String? = nil
    @State private var losowePytania: [Pytanie] = []
    @State private var odpowiedzi: [Int: Int] = [:]  // [indeksPytania: wybranaOdpowiedz]
    @State private var pokazWynik = false

    var punkty: Int {
        losowePytania.enumerated().filter { i, pytanie in
            odpowiedzi[i] == Int(pytanie.poprawna)
        }.count
    }

    var body: some View {
        NavigationView {
            if !started {
                startView
            } else {
                quizView
            }
        }
    }

    // MARK: - Start
    var startView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(red: 0.39, green: 0.19, blue: 0.35))
            Text("Sprawdź swoją wiedzę")
                .font(.title)
                .bold()

            VStack(spacing: 12) {
                Text("Liczba pytań w puli: \(pytania.count)")
                    .foregroundColor(.secondary)

                HStack {
                    Text("Liczba pytań:")
                    Spacer()
                    // Pole tekstowe spięte z surowym tekstem wpisywanym przez użytkownika
                                        TextField("5–\(pytania.count)", text: $tekstIlosciPytan)
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.center)
                                            .frame(width: 60)
                                            .padding(8)
                                            .background(Color(.secondarySystemBackground))
                                            .cornerRadius(8)
                                            
                                            // --- TUTAJ DZIEJE SIĘ WALIDACJA ---
                                            .onChange(of: tekstIlosciPytan) { nowyTekst in
                                                if nowyTekst.isEmpty {
                                                    bladWalidacji = "Pole nie może być puste!"
                                                    return
                                                }
                                                
                                                // Sprawdzanie poprawności: Czy użytkownik wpisał poprawne cyfry?
                                                guard let liczba = Int(nowyTekst) else {
                                                    bladWalidacji = "Musisz wpisać liczby!"
                                                    return
                                                }
                                                // Sprawdzanie poprawności: Czy liczba mieści się w dozwolonym zakresie?
                                                                            if liczba < 5 {
                                                                                bladWalidacji = "Minimum to 5 pytań!"
                                                                            } else if liczba > pytania.count {
                                                                                bladWalidacji = "Maksimum to \(pytania.count) pytań!"
                                                                            } else {
                                                                                // Dane wejściowe są w 100% poprawne
                                                                                bladWalidacji = nil
                                                                                iloscPytan = liczba
                                                                            }
                                                                        }
                }
                .padding(.horizontal)
                // Wizualny komunikat o błędzie dla użytkownika (i profesora!)
                                if let komunikatBledu = bladWalidacji {
                                    Text(komunikatBledu)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .bold()
                                        .transition(.opacity)
                                }
                // Suwak jako alternatywa
                Slider(
                    value: Binding(
                        get: { Double(iloscPytan) },
                        set: { nowaWartosc in
                            let liczba = Int(nowaWartosc)
                            iloscPytan = liczba
                            tekstIlosciPytan = String(liczba)
                            bladWalidacji = nil
                        }
                    ),
                    in: 5...Double(max(pytania.count, 5)),
                    step: 1
                )
                .padding(.horizontal)
                .tint(Color(red: 0.39, green: 0.19, blue: 0.35))
            }

            Spacer()
            Button {
                odpowiedzi = [:]
                pokazWynik = false
                losowePytania = Array(pytania.shuffled().prefix(iloscPytan))
                started = true
            } label: {
                Text("Rozpocznij (\(iloscPytan) pytań)")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.39, green: 0.19, blue: 0.35))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .disabled(pytania.isEmpty)
        }
        .navigationTitle("Quiz")
    }

    // MARK: - Quiz
    var quizView: some View {
        ScrollView {
            VStack(spacing: 24) {
                ForEach(Array(losowePytania.enumerated()), id: \.offset) { i, pytanie in
                    kafelekPytania(indeks: i, pytanie: pytanie)
                }

                Button {
                    pokazWynik = true
                } label: {
                    Text("Sprawdź wynik")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(odpowiedzi.count == losowePytania.count ? Color(red: 0.39, green: 0.19, blue: 0.35) : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(odpowiedzi.count < losowePytania.count)
                .padding(.horizontal)

                if pokazWynik {
                    wynikBaner
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Quiz")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Wróć") {
                    started = false
                    pokazWynik = false
                }
            }
        }
    }

    // MARK: - Kafelek pytania
    func kafelekPytania(indeks: Int, pytanie: Pytanie) -> some View {
        let listaOdpowiedzi = pytanie.odpowiedzi ?? []
        let wybrana = odpowiedzi[indeks]

        return VStack(alignment: .leading, spacing: 12) {
            Text("Pytanie \(indeks + 1)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(pytanie.tresc ?? "")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(Array(listaOdpowiedzi.enumerated()), id: \.offset) { j, odp in
                    Button {
                        if !pokazWynik {
                            odpowiedzi[indeks] = j
                        }
                    } label: {
                        HStack {
                            Image(systemName: wybrana == j ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(kolorOpcji(indeks: indeks, pytanie: pytanie, j: j))
                            Text(odp)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding(10)
                        .background(kolorTlaOpcji(indeks: indeks, pytanie: pytanie, j: j))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Baner wyniku
    var wynikBaner: some View {
        VStack(spacing: 8) {
            Text("Twój wynik")
                .font(.headline)
            Text("\(punkty) / \(losowePytania.count)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(kolorWyniku)
            Text(opisWyniku)
                .foregroundColor(.secondary)
            Button("Zagraj ponownie") {
                odpowiedzi = [:]
                pokazWynik = false
                losowePytania = Array(pytania.shuffled().prefix(10))
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Helpers
    func kolorOpcji(indeks: Int, pytanie: Pytanie, j: Int) -> Color {
        guard pokazWynik else { return odpowiedzi[indeks] == j ? Color(red: 0.39, green: 0.19, blue: 0.35) : .secondary }
        if j == Int(pytanie.poprawna) { return .green }
        if odpowiedzi[indeks] == j { return .red }
        return .secondary
    }

    func kolorTlaOpcji(indeks: Int, pytanie: Pytanie, j: Int) -> Color {
        guard pokazWynik else { return odpowiedzi[indeks] == j ? Color(red: 0.39, green: 0.19, blue: 0.35).opacity(0.1) : Color(.tertiarySystemBackground) }
        if j == Int(pytanie.poprawna) { return Color.green.opacity(0.15) }
        if odpowiedzi[indeks] == j { return Color.red.opacity(0.15) }
        return Color(.tertiarySystemBackground)
    }

    var kolorWyniku: Color {
        let procent = Double(punkty) / Double(losowePytania.count)
        if procent >= 0.8 { return .green }
        if procent >= 0.5 { return .blue }
        return .red
    }

    var opisWyniku: String {
        let procent = Double(punkty) / Double(losowePytania.count)
        if procent >= 0.8 { return "Świetny wynik!" }
        if procent >= 0.5 { return "Nieźle!" }
        return "Spróbuj jeszcze raz"
    }
}

#Preview {
    QuizView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
