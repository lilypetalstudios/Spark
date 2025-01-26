import SwiftUI
import Firebase
import FirebaseFirestore

struct LeaderboardEntry: Identifiable {
    var id: String
    var username: String
    var avatarUrl: String
    var totalPoints: Int
}

struct LeaderBoardView: View {
    @State private var leaderboardEntries: [LeaderboardEntry] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: AlertItem? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading leaderboard...")
                } else {
                    List(leaderboardEntries.indices, id: \.self) { index in
                        let entry = leaderboardEntries[index]
                        HStack {
                            Text("\(index + 1).")
                                .font(.headline)
                                .foregroundColor(.black)
                            AsyncImage(url: URL(string: entry.avatarUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .padding(.trailing, 10)
                            } placeholder: {
                                ProgressView()
                            }
                            VStack(alignment: .leading) {
                                Text(entry.username)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                Text("\(entry.totalPoints) points")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                    }
                    .navigationTitle("leaderboard")
                }
            }
            .onAppear(perform: fetchLeaderboardData)
            .alert(item: $errorMessage) { error in
                Alert(title: Text(error.title), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    func fetchLeaderboardData() {
        let db = Firestore.firestore()
        db.collection("users")
            .order(by: "totalPoints", descending: true)
            .limit(to: 10) 
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = AlertItem(title: "Error", message: "Failed to fetch leaderboard data: \(error.localizedDescription)")
                    isLoading = false
                    return
                }

                guard let documents = snapshot?.documents else {
                    errorMessage = AlertItem(title: "Error", message: "No users found.")
                    isLoading = false
                    return
                }

                leaderboardEntries = documents.compactMap { doc in
                    let data = doc.data()
                    return LeaderboardEntry(
                        id: doc.documentID,
                        username: data["username"] as? String ?? "Unknown",
                        avatarUrl: data["avatar"] as? String ?? "",
                        totalPoints: data["totalPoints"] as? Int ?? 0
                    )
                }

                isLoading = false
            }
    }
}

struct LeaderBoardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderBoardView()
    }
}
