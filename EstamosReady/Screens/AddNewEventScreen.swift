//
//  AddNewEventScreen.swift
//  EstamosReady
//
//  Created by Husnain on 12/09/2022.
//

import SwiftUI
import AVKit
import MediaPlayer
import MobileCoreServices
import Photos
import UIKit


struct AddNewEventScreen : View {
    
    @Binding var showNewEventScreen: Bool
    @Binding var audio: URL?
    
    @State private var showingSongPicker = false
    
    @State var showRecordVideoScreen:Bool = false
    @State var fileName = ""
    
    @Binding var eventName:String
    @Binding var videoOrientation:String
    @Binding var isSlowMotion:String
    
    let orientations = ["Portrait","Landscaped"]
    
    let slowMotionEffect = ["Yes","No"]
    
    

    
    
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
                    .padding(.top,16)
                    .padding(.vertical)
                    //                .padding(.horizontal)
                    
                    ScrollView{
                        VStack(alignment: .leading){
                            Text("New Event")
                                .foregroundColor(.white)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            //event name
                            Text("Event Name")
                                .foregroundColor(.white)
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.vertical)
                            
                            TextField("Enter Event Name", text: self.$eventName)
                                .padding()
                                .autocapitalization(.none)
                                .background(Color.white)
                                .cornerRadius(10)
                                .frame(width: UIScreen.main.bounds.width - 45)
                            
                            //audio file
                            
                            Text("Setting Audio")
                                .foregroundColor(.white)
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.vertical)
                            HStack{
                                TextField("Setting audio", text: self.$fileName)
                                    .padding()
                                    .autocapitalization(.none)
                                    .background(Color.white)
                                
                                
                                Button(action:{

                                    self.showingSongPicker = true
                                }){
                                    Text("Choose")
                                        .foregroundColor(.black)
                                        .padding(.horizontal)
                                }
                            }
                            .background(RoundedRectangle(cornerRadius:4).stroke(lineWidth: 0))
                            .background(Color.white)
                            .cornerRadius(10)
                            .frame(width: UIScreen.main.bounds.width - 45)
                            
                            //choose video orientation landscape or portrait
                            
                            Text("Recording Mode")
                                .foregroundColor(.white)
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.vertical)
                            HStack{
                                Text("\(self.videoOrientation)")
                                    .foregroundColor(self.videoOrientation == "Select Orientation" ? Color.gray:Color.black)
                                    
                                    .padding(12)
                                Spacer()
                                Menu {
                                    ForEach(0..<2){ i in
                                        DropButton(heading: orientations[i],value: self.$videoOrientation)
                                    }
                        
                                    
                                }label: {
                                    
                                    Text("Choose")
                                        .foregroundColor(.black)
                                        .padding(.horizontal)
                                }
                            }
                            .background(RoundedRectangle(cornerRadius:4).stroke(lineWidth: 0))
                            .background(Color.white)
                            .cornerRadius(10)
                            .frame(width: UIScreen.main.bounds.width - 45)
                            
                            //orientation ends
                            
                            //slowmotion heading
                            
                            Text("Add Slowmotion Effect")
                                .foregroundColor(.white)
                                .font(.headline)
                                .fontWeight(.bold)
                                .padding(.vertical)
                            HStack{
                                Text("\(self.isSlowMotion)")
                                    .foregroundColor(self.isSlowMotion == "No" ? Color.gray:Color.black)
                                    
                                    .padding(12)
                                Spacer()
                                Menu {
                                    ForEach(0..<2){ i in
                                        DropButton(heading: slowMotionEffect[i],value: self.$isSlowMotion)
                                    }
                        
                                    
                                }label: {
                                    
                                    Text("Choose")
                                        .foregroundColor(.black)
                                        .padding(.horizontal)
                                }
                            }
                            .background(RoundedRectangle(cornerRadius:4).stroke(lineWidth: 0))
                            .background(Color.white)
                            .cornerRadius(10)
                            .frame(width: UIScreen.main.bounds.width - 45)
                            
                            //slowmotion heading ends
                            
                            
                            
                            //button
                            
                            HStack(alignment: .center){
                                Spacer()
                                
                                Button(action: {
                                    //set landscape userdefault
                                    UserDefaults.standard.set(self.videoOrientation,forKey: "CameraMode")
                                    self.showNewEventScreen.toggle()
                                    
                                }) {
                                    Text("Next")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .padding()
                                }
                                .frame(width:300)
                                .background(Color.red)
                                .cornerRadius(10)
                                .padding(.top,20)
                                
                                Spacer()
                            }
                        }
                        .sheet(isPresented: $showingSongPicker) {
                            MusicPicker(audio: self.$audio,filaName: self.$fileName)
                        }
                        .inlineNavigationBarTitle("Select Audio")
//
//                        .fileImporter(isPresented: $openFile, allowedContentTypes: [.audio]){ (res) in
//                            do{
//                                let fileUrl = try res.get()
//                                self.fileURL = fileUrl
//                                UserDefaults.standard.set(self.fileURL,forKey: "userID")
//                                //                                                            self.audio = fileUrl.path
//                                //                            soundManager.playSound(sound: self.fileURL)
//                                print(self.fileURL)
//                                self.fileName = fileUrl.lastPathComponent
//                            }
//                            catch{
//                                print("error reading doc")
//                                print(error.localizedDescription)
//                            }
//                        }
                        
                    }
                    .padding(.bottom,90)
                    Spacer()
                }
                
                .padding()
            }
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        //        .navigationBarHidden(true)
        //        .navigationBarBackButtonHidden(true)
        .background(Color.black)
        
    }
}

//song picker
struct MusicPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var audio: URL?
    @Binding var filaName: String
    
    class Coordinator: NSObject, UINavigationControllerDelegate, MPMediaPickerControllerDelegate {
        var parent: MusicPicker
        
        var url: URL?
        
        init(_ parent: MusicPicker) {
            self.parent = parent
        }
        
        func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
            
            let selectedSong = mediaItemCollection.items
            
            if (selectedSong.count) > 0 {
                let songItem = selectedSong[0]
                
                parent.audio = songItem.assetURL
                parent.filaName = songItem.title!
                mediaPicker.dismiss(animated: true, completion: nil)
            }
        }
        
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MusicPicker>) -> MPMediaPickerController {
        let picker = MPMediaPickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: MPMediaPickerController, context: UIViewControllerRepresentableContext<MusicPicker>) {
        
    }
}

//drop down menu
struct DropButton: View {
    @State var heading: String
    
    @Binding var value:String
    
    var body: some View {
        Button (action:{
            self.value = self.heading
        }, label:{
            Text("\(self.heading)")
                .foregroundColor(.black)
//                .invertColor(bool: colorScheme == .dark)
        })
    }
}


