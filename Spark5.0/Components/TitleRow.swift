//
//  TitleRow.swift
//  Spark5.0
//
//  Created by sayuri patel on 10/21/24.
//

import SwiftUI

struct TitleRow: View {
    var name = "sayuri"
    var url = URL(string: "https://images.unplash.com/photo-1567532939604-b6b5b0db2604?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by2wYwd1fHx8fGVufD88fHx8")
    var body: some View {
        HStack(spacing: 20) {
            AsyncImage(url: url) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .cornerRadius(50)
            } placeholder: {
                ProgressView()
            }
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.title).bold()
                Text("Online")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "phone.fill")
                .foregroundColor(.gray)
                .padding(10)
                .background(.white)
                .cornerRadius(50)
        }
        .padding()
    }
}

struct TitleRow_PReviews: PreviewProvider {
    static var previews: some View {
        TitleRow()
            .background(Color.white)
        
    }
}

//7:11

//16:42 
