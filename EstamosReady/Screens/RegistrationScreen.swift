//
//  RegistrationScreen.swift
//  EstamosReady
//
//  Created by Husnain on 12/09/2022.
//

import SwiftUI
import UIKit
import Firebase

struct RegistrationScreen: View {
    
    @Binding var showRegisterScreen: Bool
    @Binding var showHomeScreen: Bool
    
    @State var firstName = "";
    @State var lastName = "";
    @State var ref: DatabaseReference!
    @State var email = "";
    @State var password = "";
    @State var alert = false
    @State var error = ""
    @State var userUID: String = ""
    @State var showProgress = false
    
    
    
    var body: some View {
        ZStack{
            ZStack{
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
                    
                    ScrollView{
                        VStack(alignment: .leading){
                            Text("Create Account")
                                .foregroundColor(.white)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            //first name
                            Text("First Name")
                                .foregroundColor(.white)
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.vertical)
                            
                            TextField("Enter First Name", text: self.$firstName)
                                .foregroundColor(.black)
                                .padding()
                                .autocapitalization(.none)
                                .background(Color.white)
                                .cornerRadius(10)
                                .frame(width: UIScreen.main.bounds.width - 45)
                            
                            //last name
                            
                            Text("Last Name")
                                .foregroundColor(.white)
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.vertical)
                            
                            TextField("Enter Last Name", text: self.$lastName)
                                .padding()
                                .autocapitalization(.none)
                                .background(Color.white)
                                .cornerRadius(10)
                                .frame(width: UIScreen.main.bounds.width - 45)
                            
                            
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
                            
                            
                            SecureField("Enter Password", text: self.$password)
                                .padding()
                                .autocapitalization(.none)
                                .background(Color.white)
                                .cornerRadius(10)
                                .frame(width: UIScreen.main.bounds.width - 45)
                        
                            
                            
                        }
                        
                        //button
                       
                        
                        Button(action: {
    //                        self.showHomeScreen.toggle()
                            self.showProgress.toggle()
                            self.createAccount()
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
                            .padding(.top,20)
                    }
                    .padding(.bottom,60)
                    Spacer()
                }
                .padding()
            }
            
            if self.alert{
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
      
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .background(Color.black)
        
    }
    
    func createAccount (){
        print("First Name: \(self.firstName)")
        print("Last Name: \(self.lastName)")
        print("Email: \(self.email)")
        print("Password: \(self.password)")
        
        ref = Database.database().reference()
        
        //save data in db
        
        if self.email != ""{
            
                Auth.auth().createUser(withEmail: self.email, password: self.password){
                    result,err in
                    if err != nil {
                        self.showProgress.toggle()
                        self.error = err!.localizedDescription
                        self.alert.toggle()
                        return
                    }
                    
                    self.showProgress.toggle()
                    self.ref.child("users").child(result?.user.uid ?? "").setValue(["name": self.firstName,"lastname": self.lastName,"emailaddress": self.email])
                    self.userUID = (result?.user.uid)!
                    print("User Created Successfully:\(self.userUID)")
                    
                    UserDefaults.standard.set(result?.user.uid,forKey: "userID")
                    NotificationCenter.default.post(name: Notification.Name("userID"),object: nil)
                    UserDefaults.standard.set(true,forKey: "status")
                    NotificationCenter.default.post(name: Notification.Name("status"),object: nil)
                    self.showHomeScreen.toggle()
                }
           
        }else{
            self.showProgress.toggle()
            self.error = "Please Fill all the contents"
            self.alert.toggle()
        }
    }
}


//Error popup
struct ErrorView: View{
    
    @State var color = Color.black.opacity(0.7)
    @Binding var alert: Bool
    @Binding var error: String
    var body: some View{
        GeometryReader{_ in
            VStack{
                HStack{
                    Text(self.error == "RESET" ? "Message":"Error")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(self.color)
                    Spacer()
                } //HSTACK
                .padding(.horizontal,25)
                Text(self.error == "RESET" ? "Password Reset Link Has been send to your email" : self.error)
                    .foregroundColor(self.color)
                    .padding(.top)
                    .padding(.horizontal,25)
                Button(action:{
                    self.alert.toggle()
                }){
                    Text(self.error == "RESET" ?  "Ok":"Cancel")
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .frame(width: UIScreen.main.bounds.width - 120)
                } // BUTTON
                .background(Color.red)
                .cornerRadius(10)
                .padding(.top,25)
            }//VSTACK
            .padding(.vertical, 25)
            .frame(width: UIScreen.main.bounds.width - 70)
            .background(Color.white)
            .cornerRadius(12)
            .padding(.top,25)
            .position(x: 190, y: 280)
        }//GEOMETRYREADER
        .background(Color.black.opacity(0.35).edgesIgnoringSafeArea(.all))
    }
} //ERROR POPUP

//struct RegistrationScreen_Previews: PreviewProvider {
//    static var previews: some View {
//        RegistrationScreen()
//    }
//}

