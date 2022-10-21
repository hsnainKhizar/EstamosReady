//
//  RecordVideoScreen.swift
//  EstamosReady
//
//  Created by Husnain on 12/09/2022.
//

//import SwiftUI

//
//  RecordVideoScreen.swift
//  NFCPassportReaderApp
//
//  Created by Husnain on 27/07/2022.
//  Copyright © 2022 Andy Qua. All rights reserved.
//
 
import Foundation
import SwiftUI
import UIKit

import Photos
//import Alamofire
import AVFoundation
import MobileCoreServices
import AVKit
//import CameraKit_iOS

struct RecordVideoScreen : View {
    
    @State var videoMp4Url:URL?
    var audioUrl:String
//    var photoSession:CKFPhotoSession?
//    var videoSession:CKFVideoSession?
    
//    let api = APIConnection()
    let recorder = UIImagePickerController()
//    let mainUrl = AppDelegate.mainUrl
    
    
    @StateObject var cameraModel = CameraViewModel()
    
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            
            // MARK: Camera View
            
            CameraView()
                .environmentObject(cameraModel)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .padding(.top,10)
                .padding(.bottom,30)
            
            // MARK: Controls
            ZStack{
                Button(action:{
                    if cameraModel.isRecording{
                        cameraModel.stopRecording()
                    }
                    else{
                        cameraModel.startRecording()
                    }
                }){
                    Image("Reels")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.black)
                        .opacity(cameraModel.isRecording ? 0 : 1)
                        .padding(12)
                        .frame(width: 60, height: 60)
                        .background{
                            Circle()
                                .stroke(cameraModel.isRecording ? .clear : .black)
                        }
                        .padding(6)
                        .background{
                            Circle()
                                .fill(cameraModel.isRecording ?   .red:.white)
                        }
                }
                
                //Preview buttton
                
                Button {
                    cameraModel.showPreview.toggle()
                } label: {
                    Label {
                        Image(systemName: "chevron.right")
                            .font(.callout)
                    } icon:{
                        Text("Preview")
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal,20)
                    .padding(.vertical,8)
                    .background{
                        Capsule()
                            .fill(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing)
            }//ZSTACK
            .frame(maxHeight: .infinity,alignment: .bottom)
            .padding(.top,10)
            .padding(.bottom,30)
        }//ZStack
        .overlay(content:{
            if let url = cameraModel.previewURL,cameraModel.showPreview{
                FinalPreview(url: url,audioUrl: self.audioUrl, showPreview: $cameraModel.showPreview)
//                    .transition(.move(edge: .trailing))
            }
        })
        .preferredColorScheme(.dark)
        
      
    }
    
    
   
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        recorder.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let videoUrl:URL = (info[UIImagePickerController.InfoKey.mediaURL] as? URL) else {
            print("No image found")
            return
        }
//        self.preViewImg.image = videoPreviewImage(url: videoUrl)
        
//        encodeVideo(at: videoUrl) { (url, error) in
//            if error != nil {
//                let alertError = UIAlertController(title: "Error", message: "บันทึกวีดีโอไม่สำเร็จ", preferredStyle: .alert)
//                alertError.addAction(UIAlertAction(title: "ปิด", style: .destructive, handler: nil))
////                self.present(alertError, animated: true, completion: nil)
////                self.btnPlay.isHidden = false
////                self.btnPlay.isEnabled = true
//            }
//        }

    }
}


//final preview
struct FinalPreview:View {
    var url: URL
    var audioUrl:String
    let url2 = Bundle.main.url(forResource: "1", withExtension: "mp4")
    @Binding var showPreview: Bool
    @State var alert = false
    @State var error = ""
    @State var showVideo = false
    @State var sheet = false
    @State var items: [Any] = []
//    var progressHUD = ProgressHUD(text: "Uploading...")
//    let mainUrl = AppDelegate.mainUrl
    
    var body: some View {
        ZStack{
            GeometryReader{proxy in
                let size = proxy.size
                
                VideoPlayer(player: AVPlayer(url: url))
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                
                // MARK: Upload Button
                
                    .overlay(alignment: .bottomTrailing) {
                        VStack{
                            HStack(alignment: .center){
                                Spacer()
                                
                                Button(action: {
                                    self.saveNormal()
                                }) {
                                    Text("Save Normally")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .padding()
                                }
                                .frame(width:300)
                                .background(Color.red)
                                .cornerRadius(10)
                                .padding(.bottom,14)
                                
                                Spacer()
                            }
                            HStack(alignment: .center){
                                Spacer()
                                
                                Button(action: {
                                    self.createSlowMotionVideo()
                                }) {
                                    Text("Save With SlowMotion")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .padding()
                                }
                                .frame(width:300)
                                .background(Color.red)
                                .cornerRadius(10)
                                .padding(.bottom,40)
                                
                                Spacer()
                            }
                        }
                       
                    }
                
                
            }
            .sheet(isPresented: $sheet, content: {
                ShareSheet(items: items)
            })
            if self.alert {
                ErrorViewVideo(alert: self.$alert, error: self.$error)
            }
            
//            if self.showVideo {
//                VSVideoSpeeder.shared.scaleAsset(fromURL: url ?? self.url, by: 3, withMode: SpeedoMode.Slower)
//                { (exporter) in
//                     if let exporter = exporter {
//                         switch exporter.status {
//                                case .failed: do {
//                                      print(exporter.error?.localizedDescription ?? "Error in exporting..")
//                                }
//                                case .completed: do {
//                                      print("Scaled video has been generated successfully!")
//                                }
//                                case .unknown: break
//                                case .waiting: break
//                                case .exporting: break
//                                case .cancelled: break
//                           }
//                      }
//                      else {
//                           /// Error
//                           print("Exporter is not initialized.")
//                      }
//                }
//            }
        }
        
        
        
    }//body
    
    func createSlowMotionVideo(){
        guard let sound = URL(string: "/private/var/mobile/Library/Mobile Documents/com~apple~CloudDocs/Downloads/mixkit-fast-small-sweep-transition-166.wav") else { return }
        let asset = AVURLAsset(url: self.url, options : nil)
        let audioAsset = AVURLAsset(url: sound, options : nil)

        let srcVideoTrack = asset.tracks(withMediaType: .video).first!
        let srcAudioTrack = audioAsset.tracks(withMediaType: .audio).first!

        let sloMoComposition = AVMutableComposition()
        let sloMoVideoTrack = sloMoComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        let sloMoAudioTrack = sloMoComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!

        let assetTimeRange = CMTimeRange(start: .zero, duration: asset.duration)

        try! sloMoVideoTrack.insertTimeRange(assetTimeRange, of: srcVideoTrack, at: .zero)
        try! sloMoAudioTrack.insertTimeRange(assetTimeRange, of: srcAudioTrack, at: .zero)

        let newDuration = CMTimeMultiplyByFloat64(assetTimeRange.duration, multiplier: 2)
        sloMoVideoTrack.scaleTimeRange(assetTimeRange, toDuration: newDuration)
        sloMoAudioTrack.scaleTimeRange(assetTimeRange, toDuration: newDuration)

        // you can play sloMoComposition in an AVPlayer at this point

        // Export to a file using AVAssetExportSession
        let exportSession = AVAssetExportSession(asset: sloMoComposition, presetName: AVAssetExportPresetPassthrough)!
        exportSession.outputFileType = .mp4
        exportSession.outputURL = getDocumentsDirectory().appendingPathComponent("slow-mo-\(Date.timeIntervalSinceReferenceDate).mp4")
        exportSession.exportAsynchronously {
            assert(exportSession.status == .completed)
//                                    print("File in \(exportSession.outputURL!)")
            
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exportSession.outputURL!)
                }) { saved, error in
                    if saved {
                        items.removeAll()
                        items.append(exportSession.outputURL!)
                        
                        self.sheet.toggle()
                        self.error = "Video saved Successfully!"
                        self.alert.toggle()

                    }
                }
        }
    }
    
    func saveNormal(){
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.url)
        }) { saved, error in
            if saved {
                items.removeAll()
                items.append(self.url)
                
                self.sheet.toggle()
                self.error = "Video saved Successfully!"
                self.alert.toggle()

            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
  
}


struct CameraView: View {
    
    @EnvironmentObject var cameraModel: CameraViewModel
    
    var body: some View{
        
        GeometryReader{proxy in
            let size = proxy.size
            
            CameraPreview(size: size)
                .environmentObject(cameraModel)
        }//ZStack
        .onAppear(perform:cameraModel.checkPermission)
        .alert(isPresented: $cameraModel.alert) {
            Alert(title: Text("Please Enable cameraModel Access Or Microphone Access!!!"))
        }
    }
}

// camera view model

class CameraViewModel: NSObject,ObservableObject,AVCaptureFileOutputRecordingDelegate {

    
    @Published var session = AVCaptureSession()
    
    @Published var alert = false
    
    @Published var output = AVCaptureMovieFileOutput()
    
    @Published var preview : AVCaptureVideoPreviewLayer!
    
    // MARK: Video Recorder Properties
    
    @Published var isRecording: Bool = false
    @Published var recordedURLs: [URL] = []
    @Published var previewURL: URL?
    @Published var showPreview: Bool = false
    
    
    
    
    func checkPermission(){
        
        //first checking cameraModel has got permission...
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
            // setting up session
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video){(status) in
                
                if status{
                    self.setUp()
                    
                }
            }
        case .denied:
            self.alert.toggle()
            return
        default:
            return
        }
    }
    
    func setUp(){
        // setting up cameraModel
        
        do {
            // setting configs
            self.session.beginConfiguration()
            
            let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            
            let videoInput = try AVCaptureDeviceInput(device: cameraDevice!)
            
            
            let audioDevice = AVCaptureDevice.default(for: .audio)
            
            let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            // audio input
            
            
            
            //checking and adding to session
            
            if self.session.canAddInput(videoInput) && self.session.canAddInput(audioInput){
                self.session.addInput(videoInput)
                self.session.addInput(audioInput)
            }
            
            // same fpr output
            
            if self.session.canAddOutput(self.output){
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
            
            
        }
        catch{
            print(error.localizedDescription)
        }
    }
    
    
    func startRecording(){
        // MARK: Temporary URL for recording video
        
        let tempURL = NSTemporaryDirectory() + "\(Date()).mov"
        output.startRecording(to: URL(fileURLWithPath: tempURL), recordingDelegate: self)
        isRecording = true
    }
    
    func stopRecording(){
        output.stopRecording()
        isRecording = false
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        //created successfully
        print(outputFileURL)
        self.previewURL = outputFileURL
    }
   
    
}

//setting view for preview

struct CameraPreview: UIViewRepresentable {
    
    @EnvironmentObject var cameraModel : CameraViewModel
    var size: CGSize
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        cameraModel.preview = AVCaptureVideoPreviewLayer(session: cameraModel.session)
        cameraModel.preview.frame.size = size
        
        cameraModel.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(cameraModel.preview)
        
        cameraModel.session.startRunning()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}


//share sheet

struct ShareSheet : UIViewControllerRepresentable {
    
    var items : [Any]
    
    func makeUIViewController(context: Context) -> some UIActivityViewController {
        let controller  = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}




//struct RecordVideoScreen : View {
//
//    @State var showSaveVideoScreen:Bool = false
//
//    var body:some View {
//        ZStack{
//            NavigationLink(destination: SaveVideoScreen(),isActive:self.$showSaveVideoScreen){
//                Text("")
//            }
//            .hidden()
//            VStack{
////                Text("Record Video")
////                    .foregroundColor(.white)
////                    .font(.title2)
////                    .fontWeight(.bold)
////                    .padding(.vertical)
//                Image("party")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//
//                HStack(alignment: .center){
//                    Spacer()
//
//                    Button(action: {
//                        self.showSaveVideoScreen.toggle()
//                        }) {
//                            Text("Record")
//                                .foregroundColor(.white)
//                                .font(.headline)
//                                .fontWeight(.bold)
//                                .padding()
//                       }
//                        .frame(width:300)
//                        .background(Color.red)
//                        .cornerRadius(10)
//                        .padding(.top,20)
//
//                    Spacer()
//                }
//
//                Spacer()
//            }
//            .padding()
//        }
////        .navigationBarHidden(true)
//        .background(Color.black)
//    }
//}

//struct RecordVideoScreen_Previews: PreviewProvider {
//    static var previews: some View {
//        RecordVideoScreen()
//    }
//}

struct ErrorViewVideo: View{
    
    @State var color = Color.black.opacity(0.7)
    @Binding var alert: Bool
    @Binding var error: String
    var body: some View{
        GeometryReader{_ in
            VStack{
                HStack{
                    Text(self.error == "RESET" ? "Message":"Message")
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
                    Text(self.error == "RESET" ?  "Ok":"Ok")
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


