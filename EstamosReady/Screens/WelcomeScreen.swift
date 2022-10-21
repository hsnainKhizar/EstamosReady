//
//  WelcomeScreen.swift
//  EstamosReady
//
//  Created by Husnain on 12/09/2022.
//

import SwiftUI

struct WelcomeScreen: View {
    
    @State var showLoginScreen = false;
    
    var body: some View {
    
            ZStack{
                NavigationLink(destination: LoginScreen(showLoginScreen: self.$showLoginScreen),isActive:self.$showLoginScreen){
                    Text("")
                }
                .hidden()
                VStack{
//                    Spacer()
                    Text("Welcome To")
                        .foregroundColor(.white)
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.top,20)
                        .padding(.horizontal)
                    
                    Text("Estamos Ready!")
                        .foregroundColor(.white)
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.top,10)
                        .padding(.horizontal)
                    
                    //image
                    
                   
                    
                    Image("logoEstamos")
                        .resizable()
                        .scaledToFit()
                        .frame(width:200,height:200)
                        .padding(.top,40)
                    
                    Text("This is estamos ready")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.vertical)
                    
                    
                    //button
                    Button(action: {
                        self.showLoginScreen.toggle()
                        }) {
                        Image("arrowDouble")
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .font(.largeTitle)
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color.white)
                            .background(Color.red)
                            .clipShape(Circle())
                       }
                        .padding(.top,80)

                    Spacer()
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            .background(Color.black)
     
    }
}

//struct WelcomeScreen_Previews: PreviewProvider {
//    static var previews: some View {
//        WelcomeScreen()
//    }
//}
