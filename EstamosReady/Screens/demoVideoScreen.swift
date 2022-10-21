//
//  demoVideoScreen.swift
//  EstamosReady
//
//  Created by Husnain on 22/09/2022.
//

import SwiftUI
import UIKit
//struct demoVideoScreen: UIViewController {
//    let url = Bundle.main.url(forResource: "1", withExtension: "mp4")!
//    VSVideoSpeeder.shared.scaleAsset(fromURL: url, by: 3, withMode: SpeedoMode.Slower) { (exporter) in
//         if let exporter = exporter {
//             switch exporter.status {
//                    case .failed: do {
//                          print(exporter.error?.localizedDescription ?? "Error in exporting..")
//                    }
//                    case .completed: do {
//                          print("Scaled video has been generated successfully!")
//                    }
//                    case .unknown: break
//                    case .waiting: break
//                    case .exporting: break
//                    case .cancelled: break
//               }
//          }
//          else {
//               /// Error
//               print("Exporter is not initialized.")
//          }
//    }
//}
//
//struct demoVideoScreen_Previews: PreviewProvider {
//    static var previews: some View {
//        demoVideoScreen()
//    }
//}

import UIKit
import AVFoundation
import Foundation

struct demoVideoScreen: View {
    var body:  some View {
        Text("Hello")
    }
}



enum SpeedoMode {
    case Slower
    case Faster
}



class VSVideoSpeeder: NSObject {

    /// Singleton instance of `VSVideoSpeeder`
    static var shared: VSVideoSpeeder = {
       return VSVideoSpeeder()
    }()
    
    

    /// Range is b/w 1x, 2x and 3x. Will not happen anything if scale is out of range. Exporter will be nil in case url is invalid or unable to make asset instance.
    func scaleAsset(fromURL url: URL,sound music:URL,  by scale: Int64, withMode mode: SpeedoMode) {

        /// Check the valid scale
        if scale < 1 || scale > 3 {
            /// Can not proceed, Invalid range
//            completion(nil)
            return
        }

        /// Asset
        let asset = AVAsset(url: url)
        let audioAsset = AVAsset(url: music)

        /// Video Tracks
        let videoTracks = asset.tracks(withMediaType: AVMediaType.video)
        if videoTracks.count == 0 {
            /// Can not find any video track
//            completion(nil)
            return
        }

        /// Get the scaled video duration
        let scaledVideoDuration = (mode == .Faster) ? CMTimeMake(value: asset.duration.value / scale, timescale: asset.duration.timescale) : CMTimeMake(value: asset.duration.value * scale, timescale: asset.duration.timescale)
        let timeRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)

        /// Video track
        let videoTrack = videoTracks.first!

        let mixComposition = AVMutableComposition()
        let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)

        /// Audio Tracks
        let audioTracks = asset.tracks(withMediaType: AVMediaType.audio)
        if audioTracks.count > 0 {
            /// Use audio if video contains the audio track
            let compositionAudioTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)

            /// Audio track
            let audioTrack = audioTracks.first!
            do {
                try compositionAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: CMTime.zero)
                compositionAudioTrack?.scaleTimeRange(timeRange, toDuration: scaledVideoDuration)
            } catch _ {
                /// Ignore audio error
            }
        }

        do {
            try compositionVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: CMTime.zero)
            compositionVideoTrack?.scaleTimeRange(timeRange, toDuration: scaledVideoDuration)

            /// Keep original transformation
            compositionVideoTrack?.preferredTransform = videoTrack.preferredTransform

            /// Initialize Exporter now
            let outputFileURL = URL(fileURLWithPath: "/Users/thetiger/Desktop/scaledVideo.mov")
           /// Note:- Please use directory path if you are testing with device.

            if FileManager.default.fileExists(atPath: outputFileURL.absoluteString) {
                try FileManager.default.removeItem(at: outputFileURL)
            }

            let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
            exporter?.outputURL = outputFileURL
            exporter?.outputFileType = AVFileType.mov
            exporter?.shouldOptimizeForNetworkUse = true
            exporter?.exportAsynchronously(completionHandler: {
                print(exporter)
//                completion(exporter)
            })

        } catch let error {
            print(error.localizedDescription)
//            completion(nil)
            return
        }
    }

}

