//
//  HomeScreen.swift
//  EstamosReady
//
//  Created by Husnain on 12/09/2022.
//

import SwiftUI
import AVKit
 



struct HomeScreen: View {
    
    @State var showHomeScreen: Bool = false
    @State var showRecordVideoScreen:Bool = false
    @State private var videoPlayer: AVPlayer?
    
    
    
    
    public let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    @State private var selection = 0
    
    ///  images with these names are placed  in my assets
    let images = ["party1","party2","party3","party4"]
    
    let adaptiveColumns = [
       GridItem(),
       GridItem(),
   ]
    
    @State var recentVideos = (UserDefaults.standard.object(forKey: "recentVideos") as? [String])
    
    @State var currentVideo = ""
    
    @State var showNewEventScreen = false
    @State private var isVideoPlayerPresented: Bool = false
    @State var showProfileScreen = false
    
    
    @State var audio:URL?
    @State var eventName = ""
    @State var videoOrientation = "Select Orientation"
    @State var isSlowMotion = "No"
         
    var body: some View {
        
        ZStack{
            ZStack{
                NavigationLink(destination: CameraFilterView(audio:self.$audio,eventName: self.$eventName,videoOrientation: self.$videoOrientation,isSlowMotion: self.$isSlowMotion),isActive:self.$showNewEventScreen){
                    Text("")
                }
                .hidden()
                
                
                
                NavigationLink(destination: AddNewEventScreen(showNewEventScreen: self.$showNewEventScreen,audio: self.$audio,eventName: self.$eventName,videoOrientation: self.$videoOrientation,isSlowMotion: self.$isSlowMotion),isActive:self.$showRecordVideoScreen){
                    Text("")
                }
                .hidden()
                
                NavigationLink(destination: ProfileScreen(),isActive:self.$showProfileScreen){
                    Text("")
                }
                .hidden()
                
                VStack{
                    
                    
                    HStack(alignment: .center){
                        Image("logoEstamos")
                            .resizable()
                            .scaledToFit()
                            .frame(width:80,height: 80)
                        //                        .cornerRadius(10)
                        
                        Text("This is Estamos App where you can upload videos")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .frame(width: UIScreen.main.bounds.width - 34)
                    .padding(.top,20)
                    .padding(.vertical)
                    .padding(.horizontal)
                    
                    ScrollView{
                        FeaturedTabView()
                            .frame(height: UIScreen.main.bounds.width / 1.475)
                            .padding(.vertical, 10)
                            .padding(.horizontal)
                        
                        
                        //Profile and new event buttons
                        
                        HStack(alignment: .center){
                            Spacer()
                            Button(action: {
                                self.showRecordVideoScreen.toggle()
                            }) {
                                Image(systemName: "plus")
                                    .renderingMode(.template)
                                    .foregroundColor(.white)
                                    .font(.largeTitle)
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(Color.white)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                            }
                            Spacer()
                            Button(action: {
                                self.showProfileScreen.toggle()
                                //                    self.showRegisterScreen.toggle()
                            }) {
                                Image(systemName: "gearshape")
                                    .renderingMode(.template)
                                    .foregroundColor(.white)
                                    .font(.largeTitle)
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(Color.white)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                        }//HStack
                        
                        //previous
                         
                        HStack{
                            Text("Previous")
                                .foregroundColor(.white)
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding()
                            Spacer()
                        }
                        .frame(width: UIScreen.main.bounds.width - 34)
                        .background(Color.orange)
                        .cornerRadius(8)
                        .padding(.vertical)
                        
                        
                        LazyVGrid(columns: adaptiveColumns, spacing: 20) {
                            ForEach(recentVideos ?? [], id: \.self) { number in
                                ZStack{
                                    VideoPlayer(player: AVPlayer(url:  URL(string: "\(number)")!))
                                        .frame(height: 200)
                                        .onTapGesture{
                                            
                                            self.isVideoPlayerPresented.toggle()
                                            videoPlayer = AVPlayer(url:  URL(string: "\(number)")!)
                                            //                                            print("navigate,\(self.showPreviewScreen)")
                                        }
                                }
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 34)
                        .padding(.vertical)
                        .padding(.horizontal,22)
                                                
                        //previous videos
                        
                        
                        
//                        HStack(spacing:16){
//                            VStack(spacing: 13){
//                                Image("party1")
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fill)
//                                    .frame(width: 150,height:120)
//                                    .cornerRadius(12)
//                                Text("Event 1")
//                                    .foregroundColor(.white)
//                                    .font(.footnote)
//                                    .fontWeight(.bold)
//                                    .padding(.top,10)
//                            }
//
//                            Spacer()
//
//                            VStack(spacing: 13){
//                                Image("party2")
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fill)
//                                    .frame(width: 150,height:120)
//                                    .cornerRadius(12)
//                                Text("Event 2")
//                                    .foregroundColor(.white)
//                                    .font(.footnote)
//                                    .fontWeight(.bold)
//                                    .padding(.top,10)
//                            }
//
//                        }
//                        .frame(width: UIScreen.main.bounds.width - 34)
//                        .padding(.vertical)
//                        .padding(.horizontal,22)
//
//                        //second row
//                        HStack(spacing:16){
//                            VStack(spacing: 13){
//                                Image("party3")
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fill)
//                                    .frame(width: 150,height:120)
//                                    .cornerRadius(12)
//                                Text("Event 3")
//                                    .foregroundColor(.white)
//                                    .font(.footnote)
//                                    .fontWeight(.bold)
//                                    .padding(.top,10)
//                            }
//                            Spacer()
//
//                            VStack(spacing: 13){
//                                Image("party4")
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fill)
//                                    .frame(width: 150,height:120)
//                                    .cornerRadius(12)
//                                Text("Event 4")
//                                    .foregroundColor(.white)
//                                    .font(.footnote)
//                                    .fontWeight(.bold)
//                                    .padding(.top,10)
//                            }
//
//                        }
//                        .padding(.vertical)
//                        .padding(.horizontal,22)
                    }
                    .padding(.bottom,30)//scroll
                    
                    Spacer()
                }
                .sheet(isPresented: $isVideoPlayerPresented, content: {
                    if let player = videoPlayer {
                        VideoPlayer(player: player).onAppear(perform: {
                            player.play()
                        })
                        .frame(minHeight: 480)
                        .overlay(videoPlayerOverlay)
                    }
                })
                .toolbar(content: { Spacer() })
            
                
            }
        }
        .onAppear(perform: {
            UserDefaults.standard.set("",forKey: "CameraMode")
        })
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .background(Color.black)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .padding(.horizontal)
    }
    private var videoPlayerOverlay: some View {
        VStack {
            HStack {
                Button("Dismiss", action: {
                    isVideoPlayerPresented = false
                }).roundedRectangleButtonStyle()
                Spacer()
        }.padding()
            Spacer()
    }
    }
}

//struct HomeScreen_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeScreen()
//    }
//}
