import SwiftUI

struct SignInSignUp: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Image("signinsignup")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .offset(x: -35)

                VStack(spacing: 20) {
                    NavigationLink(destination: SignUp()) {
                        Text("sign up")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(width: 350, height: 50)
                            .background(Color(red: 0.9686, green: 0.8235, blue: 0.5412))
                            .cornerRadius(15)
                    }
                    
                    NavigationLink(destination: SignIn()) {
                        Text("sign in")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(width: 350, height: 50)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                    }
                }
                .padding(.top, 450)
                .padding(.horizontal)
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    SignInSignUp()
}

