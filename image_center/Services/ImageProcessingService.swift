//
// Created by Владимир Костин on 08.06.2020.
// Copyright (c) 2020 kostin. All rights reserved.
//

import Foundation
import AVFoundation

class ImageProcessingService {
    private var trackingState = TrackingState.disabled
    private var previousImage: UIImage?

    func updateAndGetTrackingState() -> TrackingState {
        if (trackingState == .enabled) {
            trackingState = .disabled
        } else {
            trackingState = .enabled
        }
        return trackingState
    }

    func isCameraMoved(image: UIImage) -> Bool {
        return CameraMovementChecker.cameraMoved(image, prevImage: previousImage)
    }

    func process(image: UIImage) -> UIImage {
        var capturedImage = image

        if (self.trackingState == .enabled) {
            if (self.isCameraMoved(image: capturedImage)) {
                capturedImage = ImageCenterFinder.process(capturedImage)
            }
        }
        return capturedImage
    }

    
}

enum TrackingState {
    case enabled
    case disabled
}
