import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct AppUser: Identifiable {
    var id: String
    var username: String
    var bio: String
    var profilePictureUrl: String
    var accomplishments: String
    var strengths: String
    var weaknesses: String
    var totalPoints: Int
}

struct AlertItem: Identifiable {
    var id = UUID()
    var title: String
    var message: String
}

struct HomePage: View {
    @State private var avatarImageUrl: String = ""
    @State private var userName: String = "User"
    @State private var totalPoints: Int = 0
    @State private var isLoading: Bool = true
    @State private var errorMessage: AlertItem? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white

                VStack {
                    Spacer()
                    
                    HStack {
                        Text("**hello,**")
                            .font(.system(size: 40.0))
                            .foregroundColor(.black)
                            .offset(y: 90)
                        Text("**\(userName)!**")
                            .font(.system(size: 40.0))
                            .foregroundColor(Color(red: 0.9686, green: 0.8235, blue: 0.5412))
                            .offset(y: 90)
                    }
                    
                
                    if !avatarImageUrl.isEmpty {
                        AsyncImage(url: URL(string: avatarImageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .offset(y: 110)

                        } placeholder: {
                            ProgressView()
                        }

                        Text(userName)
                            .font(.headline)
                            .padding()
                            .offset(y: 80)
                    }
                    
                    Spacer()

                    if isLoading {
                        ProgressView("Loading user data...")
                    }
                
                    ZStack {
                        RoundedRectangle(cornerRadius: 50)
                            .fill(Color(red: 0.9686, green: 0.8235, blue: 0.5412))
                            .frame(width: 400, height: 480)
                            .offset(y: 100)
                            .overlay(
                                Text("**my stats**")
                                    .offset(y: -95)
                                    .font(.system(size: 30))
                            )

                        ScrollView {
                            VStack(spacing: 20) {
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white)
                                        .frame(width: 350, height: 100)
                                        .overlay(
                                            Text("**\(totalPoints) points earned**")
                                                .offset(x: 20)
                                        )
                                    Image(systemName: "trophy.fill")
                                        .foregroundColor(Color(red: 255/255, green: 180/255, blue: 52/255))
                                        .font(.system(size: 40))
                                        .offset(x: -70)
                                }
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white)
                                        .frame(width: 350, height: 100)
                                        .overlay(
                                            Text("**1 match made**")
                                                .offset(x: 30)
                                        )
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color(red: 0.3765, green: 0.5176, blue: 0.8))
                                        .offset(x: -70)
                                }
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white)
                                        .frame(width: 350, height: 100)
                                        .overlay(
                                            Text("**0 tasks**")
                                                .offset(x: 10)
                                        )
                                    Image(systemName: "pencil.and.list.clipboard")
                                        .font(.system(size: 40))
                                        .offset(x: -50)
                                        .foregroundColor(Color(red: 96/255, green: 68/255, blue: 60/255))
                                    
                                }
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white)
                                        .frame(width: 350, height: 100)
                                        .overlay(
                                            Text("**unranked**")
                                                .offset(x: 10)
                                        )
                                    Image(systemName: "medal.fill")
                                        .font(.system(size: 40))
                                        .offset(x: -50)
                                        .foregroundColor(Color.gray)
                                }
                            }
                            .padding(.bottom, 100)
                        }
                        .frame(width: 350, height: 400)
                        .offset(y: 140)
                    }
                    
                    buttonBar
                }
                .onAppear(perform: fetchUserData)
            }
            .alert(item: $errorMessage) { error in
                Alert(title: Text(error.title), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
            .navigationBarBackButtonHidden(true)
        }
    }

    private var buttonBar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black)
                .frame(width: 450, height: 100)
            HStack {
                NavigationLink(destination: MatchView()) {
                    VStack {
                        Image(systemName: "flame")
                            .foregroundColor(.white)
                    }
                    .padding()
                }

                NavigationLink(destination: TaskView()) {
                    VStack {
                        Image(systemName: "book")
                            .foregroundColor(.white)
                    }
                    .padding()
                }

                NavigationLink(destination: ChatView()) {
                    VStack {
                        Image(systemName: "message")
                            .foregroundColor(.white)
                    }
                    .padding()
                }

                NavigationLink(destination: EmptyView()) {
                    VStack {
                        Image(systemName: "bell")
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                
                NavigationLink(destination: LeaderBoardView()) {
                    VStack {
                        Image(systemName: "medal")
                            .foregroundColor(.white)
                    }
                    .padding()
                }
            }
        }
        .padding()
    }

    func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = AlertItem(title: "Error", message: "User not logged in.")
            return
        }

        let db = Firestore.firestore()

        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                errorMessage = AlertItem(title: "Error", message: "Failed to fetch user data: \(error.localizedDescription)")
                isLoading = false
                return
            }

            guard let data = snapshot?.data() else {
                errorMessage = AlertItem(title: "Error", message: "User data not found.")
                isLoading = false
                return
            }

            avatarImageUrl = data["avatar"] as? String ?? ""
            userName = data["username"] as? String ?? "User"
            totalPoints = data["totalPoints"] as? Int ?? 0 

            isLoading = false
        }
    }
}

struct HomePage_Previews: PreviewProvider {
    static var previews: some View {
        HomePage()
    }
}
