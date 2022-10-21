//
//  FeaturedItemView.swift
//  EstamosReady
//
//  Created by Husnain on 09/09/2022.
//

import SwiftUI

struct FeaturedItemView: View {
   
    
    let image: String
    
    var body: some View {
        Image(image)
            .resizable()
            .scaledToFit()
            .frame(width: UIScreen.main.bounds.width - 34)
            .cornerRadius(12)
    }
}


