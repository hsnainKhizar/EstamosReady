//
//  ContentView.swift
//  EstamosReady
//
//  Created by Husnain on 05/09/2022.
//

import SwiftUI
import Firebase

struct ContentView: View {
    
    @State var userID = UserDefaults.standard.value(forKey: "userID") as? String ?? ""
    @State var status = UserDefaults.standard.value(forKey: "status") as? Bool ?? false
    
    init() {
        FirebaseApp.configure()
        UITextField.appearance().tintColor = UIColor.red
//        UITextView.appearance().tintColor = .systemPink
    }
    
    var body: some View {
        
        NavigationView{
//            Home()
            
            if self.status {
                HomeScreen()
            }else{
                WelcomeScreen()
            }
        }
        .accentColor(.white)
        .onAppear{
            NotificationCenter.default.addObserver(forName: Notification.Name("status"), object: nil, queue: .main){(_) in
                self.status =  UserDefaults.standard.value(forKey: "status") as? Bool ?? false
               
            }
            NotificationCenter.default.addObserver(forName: Notification.Name("userID"), object: nil, queue: .main){(_) in
                self.userID =  UserDefaults.standard.value(forKey: "userUID") as? String ?? ""
            }
        }
        
      
    }
}

//struct Home:View {
//    
//   
//    @State var status = UserDefaults.standard.value(forKey: "status") as? Bool ?? false
//    
//   
//    var body: some View {
//        if self.status {
//            HomeScreen()
//        }else{
//            WelcomeScreen()
//        }
//        
//    }
//}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
