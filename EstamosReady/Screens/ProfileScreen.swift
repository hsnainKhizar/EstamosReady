//
//  ProfileScreen.swift
//  EstamosReady
//
//  Created by Husnain on 22/09/2022.
//

import SwiftUI
import Firebase
 
struct ProfileScreen: View {
    
    @State var userID: String = UserDefaults.standard.value(forKey: "userID") as? String ?? ""
    
    @State var name = ""
    @State var lastname = ""
    @State var emailaddress = ""
    
    var body: some View {
        ZStack{
            if (self.name != ""){
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
                        .padding(.top,16)
                        .padding(.vertical)
                        //                .padding(.horizontal)
                        
                        ScrollView{
                            VStack(alignment: .leading){
                                
                                HStack{
                                    Text("Hola!")
                                        .foregroundColor(.white)
                                        .font(.title)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }.padding(.horizontal)
                                
                                HStack{
                                    Spacer()
                                    Text("\(self.name)")
                                        .foregroundColor(.white)
                                        .font(.title)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }.padding(.horizontal)
                                
                                Divider()
                                Divider()
                                
                                HStack{
                                    Text("Name:")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("\(self.name)")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                }.padding(.horizontal)
                                
                                //last name
                                
                                HStack{
                                    Text("Last Name:")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("\(self.lastname)")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                }
                                .padding(.vertical)
                                .padding(.horizontal)
                                
                                //email
                                
                                HStack{
                                    Text("Email:")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text("\(self.emailaddress)")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    
                                }.padding(.horizontal)
                                
                                
                            }
                            
                            //button
                            
                            HStack(alignment: .center){
                                Spacer()
                                
                                Button(action: {
                                    self.userSignOut()
                                }) {
                                    Text("Logout")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .padding()
                                }
                                .frame(width:300)
                                .background(Color.red)
                                .cornerRadius(10)
                                .padding(.top,30)
                                
                                Spacer()
                            }
                            
                            
                            
                        }
                        .padding(.bottom,90)
                        
                        
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            else{
                ProgressView {
                    Text("Loading...")
                        .foregroundColor(.white)
                        .font(.title)
                }
            }
           
        }
        .onAppear{
            self.getUserData()
        }
        .accentColor(.white)
        //        .navigationBarBackButtonHidden(true)
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .background(Color.black)
    }
    
    func getUserData(){
        print("getUserData:\(self.userID)")
        var ref: DatabaseReference
        ref = Database.database().reference()
        ref.child("users/\(self.userID)").getData(completion:  { error, snapshot in
          guard error == nil else {
            print(error!.localizedDescription)
            return;
          }
            let value = snapshot?.value as? NSDictionary
            //print(value)
            name = value? ["name"] as? String ?? ""
            lastname = value? ["lastname"] as? String ?? ""
            emailaddress = value? ["emailaddress"] as? String ?? ""
        });//userdata
    }
    
    func userSignOut(){
        try! Auth.auth().signOut()
        UserDefaults.standard.set("", forKey: "userID")
        NotificationCenter.default.post(name: Notification.Name("userID"), object: nil)
        UserDefaults.standard.set(false, forKey: "status")
        NotificationCenter.default.post(name: Notification.Name("status"), object: nil)
    }//SIGNOUTFUNC
}

//struct ProfileScreen_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfileScreen()
//    }
//}

struct UserDataModel:Codable,Identifiable {
    var id: String
    var name: String
    var lastname : String
    var emailaddress: String
  
}
