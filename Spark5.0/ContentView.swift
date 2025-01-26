import SwiftUI

struct ImageCarouselView: View {
    let images = ["screen11", "screen22", "screen33", "screen44", "screen55"]
    @State private var currentIndex = 0
    @State private var isLastImage = false
    @State private var navigateToSignInSignUp = false

    var body: some View {
        ZStack {
            TabView(selection: $currentIndex) {
                ForEach(0..<images.count, id: \.self) { index in
                    Image(images[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .clipped()
                        .tag(index)
                        .offset(y: -12)
                        .onChange(of: currentIndex) { newValue in
                            if newValue == images.count - 1 {
                                isLastImage = true
                                startNavigationTimer()
                            } else {
                                isLastImage = false
                            }
                        }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .ignoresSafeArea(.all) 

            NavigationLink(destination: SignInSignUp(), isActive: $navigateToSignInSignUp) {
                EmptyView()
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    func startNavigationTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { 
            navigateToSignInSignUp = true
        }
    }
}
struct ContentView: View {
    var body: some View {
        NavigationStack {
            ImageCarouselView()
        }
    }
}

#Preview {
    ContentView()
}
