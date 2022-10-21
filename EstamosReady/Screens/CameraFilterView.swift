//
//  CameraFilterView.swift
//  EstamosReady
//
//  Created by Husnain on 25/09/2022.
//

//
//  CameraFilterView.swift
//  MetalPetalDemo
//
//  Created by YuAo on 2021/4/3.
//

import UIKit
import AVFoundation
import AssetsLibrary
import MediaPlayer
import MobileCoreServices
import Foundation
import SwiftUI
import MetalPetal
import VideoIO
import VideoToolbox
import Photos
import AVKit

var mode = "Landscaped"


class CapturePipeline: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    struct Face {
        var bounds: CGRect
    }
    
    enum Effect: String, Identifiable, CaseIterable {
        case none = "No Filter"
        case grayscale = "Gray Scale"
        case colorHalftone = "Color Halftone"
        case colorGrading = "Color Grading (Color Lookup)"
        case instant = "CIPhotoEffectInstant"
        case bloom = "CIBloom"
        
#if os(iOS)
        case faceTrackingPixellate = "Face Tracking Pixellate"
#endif
        
        var id: String { rawValue }
        
        typealias Filter = (MTIImage, [Face]) -> MTIImage
        
        func makeFilter() -> Filter {
            switch self {
            case .none:
                return { image, faces in image }
            case .grayscale:
                return { image, faces in image.adjusting(saturation: 0) }
            case .colorHalftone:
                let filter = MTIColorHalftoneFilter()
                filter.scale = 16
                return { image, faces in
                    filter.inputImage = image
                    return filter.outputImage!
                }
            case .colorGrading:
                let filter = MTIColorLookupFilter()
                filter.inputColorLookupTable = DemoImages.colorLookupTable
                return { image, faces in
                    filter.inputImage = image
                    return filter.outputImage!
                }
            case .instant:
                let filter = MTICoreImageUnaryFilter()
                filter.filter = CIFilter(name: "CIPhotoEffectInstant")
                return { image, faces in
                    filter.inputImage = image
                    return filter.outputImage!
                }
            case .bloom:
                return { image, faces in
                    MTICoreImageKernel.image(byProcessing: [image], using: { inputs in
                        let extent = inputs[0].extent
                        return inputs[0].clampedToExtent().applyingFilter("CIBloom").cropped(to: extent)
                    }, outputDimensions: image.dimensions)
                }
#if os(iOS)
            case .faceTrackingPixellate:
                return { image, faces in
                    let kernel = MTIPixellateFilter.kernel()
                    var renderCommands: [MTIRenderCommand] = []
                    renderCommands.append(MTIRenderCommand(kernel: .passthrough, geometry: MTIVertices.fullViewportSquare, images: [image], parameters: [:]))
                    for face in faces {
                        let normalizedX = Float(face.bounds.origin.x / image.size.width)
                        let normalizedY = Float(face.bounds.origin.y / image.size.height)
                        let normalizedWidth = Float(face.bounds.width / image.size.width)
                        let normalizedHeight = Float(face.bounds.height / image.size.height)
                        let vertices = MTIVertices(vertices: [
                            MTIVertex(x: normalizedX * 2 - 1, y: (1.0 - normalizedY - normalizedHeight) * 2 - 1, z: 0, w: 1, u: normalizedX, v: normalizedY + normalizedHeight),
                            MTIVertex(x: (normalizedX + normalizedWidth) * 2 - 1, y: (1.0 - normalizedY - normalizedHeight) * 2 - 1, z: 0, w: 1, u: normalizedX + normalizedWidth, v: normalizedY + normalizedHeight),
                            MTIVertex(x: normalizedX * 2 - 1, y: (1.0 - normalizedY) * 2 - 1, z: 0, w: 1, u: normalizedX, v: normalizedY),
                            MTIVertex(x: (normalizedX + normalizedWidth) * 2 - 1, y: (1.0 - normalizedY) * 2 - 1, z: 0, w: 1, u: normalizedX + normalizedWidth, v: normalizedY),
                        ], primitiveType: .triangleStrip)
                        let faceRenderCommand = MTIRenderCommand(kernel: kernel, geometry: vertices, images: [image], parameters: ["scale": SIMD2<Float>(30, 30)])
                        renderCommands.append(faceRenderCommand)
                    }
                    return MTIRenderCommand.images(byPerforming: renderCommands, outputDescriptors: [MTIRenderPassOutputDescriptor(dimensions: image.dimensions, pixelFormat: .unspecified)])[0]
                }
#endif
            }
        }
    }
    
    struct State {
        var isRecording: Bool = false
        var isVideoMirrored: Bool = true
    }
    
    @Published private var stateChangeCount: Int = 0
    
    private var _state: State = State()
    
    private let stateLock = MTILockCreate()
    
    private(set) var state: State {
        get {
            stateLock.lock()
            defer {
                stateLock.unlock()
            }
            return _state
        }
        set {
            stateLock.lock()
            defer {
                stateLock.unlock()
                
                //ensure that the state update happens on main thread.
                dispatchPrecondition(condition: .onQueue(.main))
                stateChangeCount += 1
            }
            _state = newValue
        }
    }
    
    @Published var previewImage: CGImage?
    
    private let renderContext = try! MTIContext(device: MTLCreateSystemDefaultDevice()!)
    
    private let queue: DispatchQueue = DispatchQueue(label: "org.metalpetal.capture")
    
    let camera: Camera = {
        
        
       
        var configurator = Camera.Configurator()
#if os(iOS)
        let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.windowScene != nil })?.windowScene?.interfaceOrientation
#endif
        configurator.videoConnectionConfigurator = { camera, connection in
#if os(iOS)
            switch interfaceOrientation {
            case .landscapeLeft:
                connection.videoOrientation = .landscapeLeft
            case .landscapeRight:
                connection.videoOrientation = .landscapeRight
            case .portraitUpsideDown:
                connection.videoOrientation = .portraitUpsideDown
            default: 
                if ( UserDefaults.standard.value(forKey: "CameraMode") as? String ?? "" == "Landscaped"){
                    connection.videoOrientation = .landscapeRight
                }else{
                    connection.videoOrientation = .portrait
                }
            }
#else
            connection.videoOrientation = .portrait
#endif
        }
        return Camera(captureSessionPreset: .hd1280x720, defaultCameraPosition: .back,  configurator: configurator)
    }()
    
    private let imageRenderer = PixelBufferPoolBackedImageRenderer()
    
    private var filter: Effect.Filter = { image, faces in image }
    
    private var faces: [Face] = []
    
    private var isMetadataOutputEnabled: Bool = false
    
    private var recorder: MovieRecorder?
    
    @Published var effect: Effect = .none {
        didSet {
            let filter = effect.makeFilter()
            let currentEffect = effect
            queue.async {
#if os(iOS)
                if currentEffect == .faceTrackingPixellate && !self.isMetadataOutputEnabled {
                    self.camera.stopRunningCaptureSession()
                    try? self.camera.enableMetadataOutput(for: [.face], on: self.queue, delegate: self)
                    self.camera.startRunningCaptureSession()
                    self.isMetadataOutputEnabled = true
                }
#endif
                self.filter = filter
            }
        }
    }
    
    override init() {
        super.init()
        try? self.camera.enableVideoDataOutput(on: queue, delegate: self)
        try? self.camera.enableAudioDataOutput(on: queue, delegate: self)
        self.camera.videoDataOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
    }
    
    func startRunningCaptureSession() {
        queue.async {
           
            self.camera.startRunningCaptureSession()
        }
    }
    
    func stopRunningCaptureSession() {
        queue.async {
            
            self.camera.stopRunningCaptureSession()
        }
    }
    
    func startRecording() throws {
        let sessionID = UUID()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(sessionID.uuidString).mp4")
        // record audio when permission is given
        let hasAudio = self.camera.audioDataOutput != nil
        let recorder = try MovieRecorder(url: url, configuration: MovieRecorder.Configuration(hasAudio: hasAudio))
        state.isRecording = true
        queue.async {
            self.recorder = recorder
        }
    }
    
    func stopRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        if let recorder = recorder {
            recorder.stopRecording(completion: { error in
                self.state.isRecording = false
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(recorder.url))
                }
            })
            queue.async {
                self.recorder = nil
            }
        }
    }
    
    func toggleVideoMirrored() {
        self.state.isVideoMirrored = !self.state.isVideoMirrored
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let formatDescription = sampleBuffer.formatDescription else {
            return
        }
        switch formatDescription.mediaType {
        case .audio:
            do {
                try self.recorder?.appendSampleBuffer(sampleBuffer)
            } catch {
                print(error)
            }
        case .video:
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            do {
                let image = MTIImage(cvPixelBuffer: pixelBuffer, alphaType: .alphaIsOne)
                let filterOutputImage = self.filter(image, faces)
                let outputImage = self.state.isVideoMirrored ? filterOutputImage.oriented(.upMirrored) : filterOutputImage
                let renderOutput = try self.imageRenderer.render(outputImage, using: renderContext)
                try self.recorder?.appendSampleBuffer(SampleBufferUtilities.makeSampleBufferByReplacingImageBuffer(of: sampleBuffer, with: renderOutput.pixelBuffer)!)
                DispatchQueue.main.async {
                    self.previewImage = renderOutput.cgImage
                }
            } catch {
                print(error)
            }
        default:
            break
        }
    }
}

#if os(iOS)

extension CapturePipeline: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        var faces = [Face]()
        for faceMetadataObject in metadataObjects.compactMap({ $0 as? AVMetadataFaceObject}) {
            if let rect = self.camera.videoDataOutput?.outputRectConverted(fromMetadataOutputRect: faceMetadataObject.bounds) {
                faces.append(Face(bounds: rect.insetBy(dx: -rect.width/4, dy: -rect.height/4)))
            }
        }
        self.faces = faces
    }
}

#endif
 

struct CameraFilterView: View {
    @StateObject private var capturePipeline = CapturePipeline()
    
     
    
    @State var finalVideoLink: URL?
    @State var audioAsset: AVAsset?
    @State var videoLink = ""
    @State var mergedAudioVideoURl:URL?
    @State var items: [Any] = []
    @State var sheet = false
    @State var alert = false
    @State var showProgress = false
    @State private var errorShow = ""
    @State private var isRecordButtonEnabled: Bool = true
    @State private var isVideoPlayerPresented: Bool = false
    
    enum SpeedoMode {
        case Slower
        case Faster
    }
    
    var selectedVideoLevel = 1.0
    var selectedMusicLevel = 1.0
    
    
    let userID = UserDefaults.standard.value(forKey: "userID") as? URL
    
    //binding values
    @Binding var audio: URL?
    @Binding var eventName:String
    @Binding var videoOrientation:String
    @Binding var isSlowMotion:String
    
    
    
    //userdefauls recent video
    @State var userData = UserDefaults.standard.array(forKey: "recentVideos") as? [String] ?? [String]()
    
    
    @State private var error: Error?
    @State private var videoPlayer: AVPlayer?
    
    var body: some View {
        ZStack {
            VStack {
                Group {
                    if let cgImage = capturePipeline.previewImage {
                        Image(cgImage: cgImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        cameraUnavailableView
                    }
                }
                .overlay(controlsView)
                
                Button(capturePipeline.state.isRecording ? "Stop Recording" : "Start Recording", action: {
                    if capturePipeline.state.isRecording {
                        isRecordButtonEnabled = false
                        capturePipeline.stopRecording(completion: { result in
                            isRecordButtonEnabled = true
                            switch result {
                            case .success(let url):
                                self.finalVideoLink = url
                                self.videoLink = url.path
                                videoPlayer = AVPlayer(url: url)
                                isVideoPlayerPresented = true
                            case .failure(let error):
                                showError(error)
                            }
                        })
                    } else {
                        videoPlayer = nil
                        isVideoPlayerPresented = false
                        do {
                            try capturePipeline.startRecording()
                        } catch {
                            showError(error)
                        }
                    }
                })
                    .disabled(!isRecordButtonEnabled)
                    .roundedRectangleButtonStyle()
                    .largeControlSize()
                //                .padding()
            }
            .background(Color.black)
            
            if let error = self.error {
                Text(error.localizedDescription)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(Color.black.opacity(0.7)))
            }
        }
        
        .frame(width: UIScreen.main.bounds.width)
        .background(Color.black)
        .onAppear(perform: {
            
            capturePipeline.startRunningCaptureSession()
        })
        .onDisappear(perform: {
            capturePipeline.stopRunningCaptureSession()
        })
        .sheet(isPresented: $sheet, content: {
            ShareSheet(items: items)
        })
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
        .inlineNavigationBarTitle("Camera")
        
    }
    
    private func showError(_ error: Error) {
        withAnimation {
            isRecordButtonEnabled = false
            self.error = error
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
            withAnimation {
                isRecordButtonEnabled = true
                self.error = nil
            }
        })
    }
    
    private var videoPlayerOverlay: some View {
        VStack {
            HStack {
                Button("Dismiss", action: {
                    isVideoPlayerPresented = false
                }).roundedRectangleButtonStyle()
                Spacer()
                Button("Save", action: {
                    //                    PHPhotoLibrary.shared().performChanges({
                    //                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: finalVideoLink!)
                    //                    }) { saved, error in
                    //                        if saved {
                    //                            items.removeAll()
                    //                            items.append(finalVideoLink)
                    //
                    //                            self.sheet.toggle()
                    //                            userData.append(self.videoLink)
                    //                            UserDefaults.standard.set(userData, forKey: "recentVideos")
                    //                            print(userData);
                    ////                            self.alert.toggle()
                    //
                    //                        }
                    //                    }
                    
//                    let audio = URL(string: "ipod-library://item/item.mp3?id=3730085394779354490")
                    
                    
                    
//                    let finalAudio = NSURL(string: "ipod-library://item/item.mp3?id=3730085394779354490")
                    
//                    print("audioLink: \(audio!)")
                    
                    
                    //func call
                    
//                    createSlowMotionVideo(video: self.finalVideoLink!)
                    
                    scaleAsset(fromURL: finalVideoLink!, sound: audio!, by: 1, withMode: SpeedoMode.Slower)
                  
                    
                }).roundedRectangleButtonStyle()
            }
            Spacer()
        }.padding()
    }
    
    private var controlsView: some View {
        VStack(alignment: .trailing) {
            HStack {
                Spacer()
                
                Picker(selection: $capturePipeline.effect, label: Text(effectPickerLabel), content: {
                    ForEach(CapturePipeline.Effect.allCases) { effect in
                        Text(effect.rawValue).tag(effect)
                            .foregroundColor(.black)
                    }
                })
                    .scaledToFit()
                    .pickerStyle(MenuPickerStyle())
                    .roundedRectangleButtonStyle()
                    .largeControlSize()
                    .animation(.none)
                
                Button(action: { [capturePipeline] in
                    capturePipeline.toggleVideoMirrored()
                }, label: { Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")})
                    .roundedRectangleButtonStyle()
                    .largeControlSize()
            }.padding()
            Spacer()
        }
    }
    
    private var effectPickerLabel: String {
#if os(iOS)
        return capturePipeline.effect.rawValue
#else
        return ""
#endif
    }
    
    private var cameraUnavailableView: some View {
        Rectangle()
            .foregroundColor(Color.gray.opacity(0.5))
            .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
            .overlay(Image(systemName: "video.fill").font(.system(size: 32))
                        .foregroundColor(Color.white.opacity(0.5)))
    }
    
    //set orientaton
    
    
    //method to merge audio with video
    
    func scaleAsset(fromURL url: URL,sound music:URL,  by scale: Int64, withMode mode: SpeedoMode) {
        
        /// Check the valid scale
        if scale < 1 || scale > 3 {
            /// Can not proceed, Invalid range
            //            completion(nil)
            return
        }
        
        /// Asset
        let asset = AVAsset(url: url)
        audioAsset = AVAsset(url: music)
        
       

        // 1 - Create AVMutableComposition object. This object
        // will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()

        // 2 - Create two video tracks
        guard
          let firstTrack = mixComposition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
          else { return }

        do {
          try firstTrack.insertTimeRange(
            CMTimeRangeMake(start: .zero, duration: asset.duration),
            of: asset.tracks(withMediaType: .video)[0],
            at: .zero)
        } catch {
          print("Failed to load first track")
          return
        }



        // 3 - Composition Instructions
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(
          start: .zero,
          duration: asset.duration)

        // 4 - Set up the instructions — one for each asset
        let firstInstruction = VideoHelper.videoCompositionInstruction(
          firstTrack,
          asset: asset)
        firstInstruction.setOpacity(0.0, at: asset.duration)
       

        // 5 - Add all instructions together and create a mutable video composition
        mainInstruction.layerInstructions = [firstInstruction]
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainComposition.renderSize = CGSize(
            width: UIScreen.main.bounds.width,
          height: UIScreen.main.bounds.height)
         

        // 6 - Audio track
        if let loadedAudioAsset = audioAsset {
          let audioTrack = mixComposition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: 0)
          do {
            try audioTrack?.insertTimeRange(
              CMTimeRangeMake(
                start: CMTime.zero,
                duration: asset.duration),
              of: loadedAudioAsset.tracks(withMediaType: .audio)[0],
              at: .zero)
          } catch {
            print("Failed to load Audio track")
          }
        }

        // 7 - Get path
        guard
          let documentDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask).first
          else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let date = dateFormatter.string(from: Date())
        let url = documentDirectory.appendingPathComponent("\(self.eventName)-\(date).mov")

        // 8 - Create Exporter
        guard let exporter = AVAssetExportSession(
          asset: mixComposition,
          presetName: AVAssetExportPresetHighestQuality)
          else { return }
        exporter.outputURL = url
        exporter.outputFileType = AVFileType.mov
        exporter.shouldOptimizeForNetworkUse = true
//        exporter.videoComposition = mainComposition

        // 9 - Perform the Export
        exporter.exportAsynchronously {
          DispatchQueue.main.async {
              print(exporter.outputURL)
                  PHPhotoLibrary.shared().performChanges({
                      PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exporter.outputURL!)
                  }) { saved, error in
                      if saved {
                          
                          print("slowmotion effect \(self.isSlowMotion)")
                          
                          if (isSlowMotion == "Yes"){
                              createSlowMotionVideo(video: exporter.outputURL!)
                          }else{
                              items.removeAll()
                              items.append(exporter.outputURL)
                              self.isVideoPlayerPresented.toggle()
                              self.sheet.toggle()
                          }
                        
//                          userData.append(self.videoLink)
//                          UserDefaults.standard.set(userData, forKey: "recentVideos")
//                          print(userData);
//                            self.alert.toggle()

                      }
                  }
          }
        }
    }
    
    
    //if user wants slowmotion video
    
    func createSlowMotionVideo(video: URL){
       
        let asset = AVURLAsset(url: video, options : nil)
       

        let srcVideoTrack = asset.tracks(withMediaType: .video).first!
        let srcAudioTrack = asset.tracks(withMediaType: .audio).first!

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
                        self.isVideoPlayerPresented.toggle()
                        self.sheet.toggle()
//                        self.error = "Video saved Successfully!"
//                        self.alert.toggle()

                    }
                }
        }
    }
    
    
    //document directory
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    
    
    
    
}

//struct CameraFilterView_Previews: PreviewProvider {
//    static var previews: some View {
//        CameraFilterView()
//    }
//}


//extensios


enum VideoHelper {
  static func orientationFromTransform(
    _ transform: CGAffineTransform
  ) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
    var assetOrientation = UIImage.Orientation.up
    var isPortrait = false
    let tfA = transform.a
    let tfB = transform.b
    let tfC = transform.c
    let tfD = transform.d

    if tfA == 0 && tfB == 1.0 && tfC == -1.0 && tfD == 0 {
      assetOrientation = .right
      isPortrait = true
    } else if tfA == 0 && tfB == -1.0 && tfC == 1.0 && tfD == 0 {
      assetOrientation = .left
      isPortrait = true
    } else if tfA == 1.0 && tfB == 0 && tfC == 0 && tfD == 1.0 {
      assetOrientation = .up
    } else if tfA == -1.0 && tfB == 0 && tfC == 0 && tfD == -1.0 {
      assetOrientation = .down
    }
    return (assetOrientation, isPortrait)
  }

  static func startMediaBrowser(
    delegate: UIViewController & UINavigationControllerDelegate & UIImagePickerControllerDelegate,
    sourceType: UIImagePickerController.SourceType
  ) {
    guard UIImagePickerController.isSourceTypeAvailable(sourceType)
      else { return }

    let mediaUI = UIImagePickerController()
    mediaUI.sourceType = sourceType
    mediaUI.mediaTypes = [kUTTypeMovie as String]
    mediaUI.allowsEditing = true
    mediaUI.delegate = delegate
    delegate.present(mediaUI, animated: true, completion: nil)
  }

  static func videoCompositionInstruction(
    _ track: AVCompositionTrack,
    asset: AVAsset
  ) -> AVMutableVideoCompositionLayerInstruction {
    let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
    let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]

    let transform = assetTrack.preferredTransform
    let assetInfo = orientationFromTransform(transform)

    var scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.width
    if assetInfo.isPortrait {
      scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.height
      let scaleFactor = CGAffineTransform(
        scaleX: scaleToFitRatio,
        y: scaleToFitRatio)
      instruction.setTransform(
        assetTrack.preferredTransform.concatenating(scaleFactor),
        at: .zero)
    } else {
      let scaleFactor = CGAffineTransform(
        scaleX: scaleToFitRatio,
        y: scaleToFitRatio)
      var concat = assetTrack.preferredTransform.concatenating(scaleFactor)
        .concatenating(CGAffineTransform(
          translationX: 0,
          y: UIScreen.main.bounds.width / 2))
      if assetInfo.orientation == .down {
        let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        let windowBounds = UIScreen.main.bounds
        let yFix = assetTrack.naturalSize.height + windowBounds.height
        let centerFix = CGAffineTransform(
          translationX: assetTrack.naturalSize.width,
          y: yFix)
        concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
      }
      instruction.setTransform(concat, at: .zero)
    }

    return instruction
  }
}
