//
//  FeaturedTabView.swift
//  EstamosReady
//
//  Created by Husnain on 09/09/2022.
//

import SwiftUI

struct FeaturedTabView: View {
    
    public let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    @State private var selection = 0
    
    let images = ["party1","party2","party3","party4"]
    
    var body: some View {
        TabView(selection : $selection){
            ForEach(0..<4){ i in
                FeaturedItemView(image: images[i])
                    .padding(.top, 10)
                    .padding(.horizontal, 15)
            }
        }// TAB
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .onReceive(timer, perform: { _ in
                            
            withAnimation{
                print("selection is",selection)
                selection = selection < 5 ? selection + 1 : 0
            }
        })
    }
}


