//
//  LoginScreen.swift
//  EstamosReady
//
//  Created by Husnain on 12/09/2022.
//

import SwiftUI
import UIKit
import Firebase


struct LoginScreen: View {
    
    @Binding var showLoginScreen: Bool
    @State var showRegisterScreen = false;
    @State var showHomeScreen = false;
    @State var email = "";
    @State var password = "";
    @State var userUID = "";
    @State var alert = false
    @State var error = ""
    @State var showProgress = false
    
    var body: some View {
        ZStack{
            ZStack{
                NavigationLink(destination: RegistrationScreen(showRegisterScreen: self.$showRegisterScreen,showHomeScreen: self.$showHomeScreen),isActive:self.$showRegisterScreen){
                    Text("")
                }
                .hidden()
                
                NavigationLink(destination: HomeScreen(),isActive:self.$showHomeScreen){
                    Text("")
                }
                .hidden()
                
                
                VStack{
                    
                    HStack(alignment: .center){
                        Image("logoEstamos")
                            .resizable()
                            .scaledToFit()
                            .frame(width:80,height: 80)
                        
                        Text("This is Estamos App where you can upload videos")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(.vertical)
                    //                .padding(.horizontal)
                    
                    ScrollView {
                        VStack(alignment: .leading){
                            Text("Log in")
                                .foregroundColor(.white)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            
                            Text("Email")
                                .foregroundColor(.white)
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.vertical)
                            
                            TextField("Enter Email", text: self.$email)
                                .padding()
                                .autocapitalization(.none)
                                .background(Color.white)
                                .cornerRadius(10)
                                .frame(width: UIScreen.main.bounds.width - 45)
                            
                            Text("Password")
                                .foregroundColor(.white)
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.vertical)
                            
                            
                            SecureField("Password", text: self.$password)
                                .padding()
                                .autocapitalization(.none)
                                .background(Color.white)
                                .cornerRadius(10)
                                .frame(width: UIScreen.main.bounds.width - 45)
                            
                            
                            
                            HStack{
                                Spacer()
                                Button(action: {
                                    self.reset()
                                }){
                                    Text("Forget Password?")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .padding(.vertical)
                                        .padding(.horizontal)
                                }
                               
                            }
                            
                            
                        }
                        
                        //button
                        
                        
                        Button(action: {
//                            self.showHomeScreen.toggle()
                            self.showProgress.toggle()
                            self.loginUser()
//                            self.showHomeScreen.toggle()
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
                        .padding(.top,60)
                        
                        HStack(alignment:.center){
                            Spacer()
                            Text("Don't have an account?")
                                .foregroundColor(.white)
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.vertical)
                            Button(action:{
                                self.showRegisterScreen.toggle()
                            }){
                                Text("Sign up")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .padding(.vertical)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.bottom,40)
                    
                    
                    
                    Spacer()
                }
                .padding()
            }
            
            if self.alert {
                ErrorView(alert: self.$alert, error: self.$error)
            }
            
            if self.showProgress {
                ProgressView {
                    Text("Loading")
                        .foregroundColor(.white)
                        .font(.title)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .background(Color.black)
    }
    
    func loginUser (){
        if self.email != "" && self.password != ""{
            
            Auth.auth().signIn(withEmail: self.email, password: self.password){
                result,err in
                if  err != nil {
                    self.showProgress.toggle()
                    self.error = err!.localizedDescription
                    self.alert.toggle()
                    return
                }
                self.userUID = (result?.user.uid)!
                print("success")
                UserDefaults.standard.set(true, forKey: "status")
                NotificationCenter.default.post(name: NSNotification.Name("status"), object: nil)
                UserDefaults.standard.set(self.userUID,forKey: "userID")
                NotificationCenter.default.post(name: NSNotification.Name("userID"),object: nil)
                self.showHomeScreen.toggle()
            }
        }else{
            self.showProgress.toggle()
            self.error = "Please fill all the contents properly"
            self.alert.toggle()
        }
    }
    
    func reset(){
        if self.email != ""{
            Auth.auth().sendPasswordReset(withEmail: email){(err) in
                if err != nil {
                    self.error = err!.localizedDescription
                    self.alert.toggle()
                    return
                }
                
                self.error = "RESET"
                self.alert.toggle()
            }
        }else{
            self.error = "Email id is invalid"
            self.alert.toggle()
        }
    }//PASS RESET FUNC
}

//struct LoginScreen_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginScreen()
//    }
//}
