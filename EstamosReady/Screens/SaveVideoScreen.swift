//
//  SaveVideoScreen.swift
//  EstamosReady
//
//  Created by Husnain on 12/09/2022.
//

import SwiftUI


struct SaveVideoScreen: View {
    
    var body:some View {
        ZStack{
           
            VStack{
//                Text("Save Video")
//                    .foregroundColor(.white)
//                    .font(.title2)
//                    .fontWeight(.bold)
//                    .padding(.vertical)
                Image("party")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                
                HStack(alignment: .center){
                    Spacer()
                    
                    Image("whatsapp")
                        .resizable()
                        .frame(width:60,height: 60)
                    Spacer()
                    Button(action: {
//                        self.showSaveVideoScreen.toggle()
                        }) {
                            Text("Save")
                                .foregroundColor(.white)
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding()
                       }
                        .frame(width:200)
                        .background(Color.red)
                        .cornerRadius(10)
                        .padding(.top,20)
                    
                    Spacer()
                }
                
                Spacer()
            }
            .padding()
        }
//        .navigationBarHidden(true)
        .background(Color.black)
    }
    
}

//struct SaveVideoScreen_Previews: PreviewProvider {
//    static var previews: some View {
//        SaveVideoScreen()
//    }
//}
