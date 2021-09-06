//
//  AVAudioPCMBuffer.swift
//  audio-trimmer-macos
//
//  Created by russell.dzhafarov@gmail.com on 06.09.2021.
//

import AVFoundation
import Accelerate

extension AVAudioPCMBuffer {
    func copy(from buffer: AVAudioPCMBuffer, readOffset: AVAudioFrameCount = 0, frames: AVAudioFrameCount = 0) -> AVAudioFrameCount {
        let remainingCapacity = frameCapacity - frameLength
        if remainingCapacity == 0 {
            print("AVAudioBuffer copy(from) - no capacity!")
            return 0
        }

        if format != buffer.format {
            print("AVAudioBuffer copy(from) - formats must match!")
            return 0
        }

        let totalFrames = Int(min(min(frames == 0 ? buffer.frameLength : frames, remainingCapacity),
                                  buffer.frameLength - readOffset))

        if totalFrames <= 0 {
            print("AVAudioBuffer copy(from) - No frames to copy!")
            return 0
        }
        
        let frameSize = Int(format.streamDescription.pointee.mBytesPerFrame)
        if let src = buffer.floatChannelData,
           let dst = floatChannelData {
            for channel in 0 ..< Int(format.channelCount) {
                memcpy(dst[channel] + Int(frameLength), src[channel] + Int(readOffset), totalFrames * frameSize)
            }
        } else if let src = buffer.int16ChannelData,
                  let dst = int16ChannelData {
            for channel in 0 ..< Int(format.channelCount) {
                memcpy(dst[channel] + Int(frameLength), src[channel] + Int(readOffset), totalFrames * frameSize)
            }
        } else if let src = buffer.int32ChannelData,
                  let dst = int32ChannelData {
            for channel in 0 ..< Int(format.channelCount) {
                memcpy(dst[channel] + Int(frameLength), src[channel] + Int(readOffset), totalFrames * frameSize)
            }
        } else {
            return 0
        }
        frameLength += AVAudioFrameCount(totalFrames)
        return AVAudioFrameCount(totalFrames)
    }
    
    func copyFrom(startSample: AVAudioFrameCount) -> AVAudioPCMBuffer? {
        guard startSample < frameLength,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameLength - startSample) else {
            return nil
        }
        let framesCopied = buffer.copy(from: self, readOffset: startSample)
        return framesCopied > 0 ? buffer : nil
    }
    
    func copyTo(count: AVAudioFrameCount) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count) else {
            return nil
        }
        let framesCopied = buffer.copy(from: self, readOffset: 0, frames: min(count, frameLength))
        return framesCopied > 0 ? buffer : nil
    }
    
    func extract(from startTime: TimeInterval, to endTime: TimeInterval) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let startSample = AVAudioFrameCount(startTime * sampleRate)
        var endSample = AVAudioFrameCount(endTime * sampleRate)

        if endSample == 0 {
            endSample = frameLength
        }

        let frameCapacity = endSample - startSample

        guard frameCapacity > 0 else {
            print("startSample must be before endSample")
            return nil
        }

        guard let editedBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else {
            print("Failed to create edited buffer")
            return nil
        }

        guard editedBuffer.copy(from: self, readOffset: startSample, frames: frameCapacity) > 0 else {
            print("Failed to write to edited buffer")
            return nil
        }
        
        return editedBuffer
    }
    
    func compressed(_ compression: Int = 100) -> [Float] {
        let inputSignal = Array(UnsafeBufferPointer(start: self.floatChannelData?[0],
                                                    count: Int(self.frameLength)))
        
        var processingBuffer = [Float](repeating: 0.0,
                                       count: Int(inputSignal.count))
        
        vDSP_vabs(inputSignal,
                  1,
                  &processingBuffer,
                  1,
                  vDSP_Length(inputSignal.count))
        
        let filter = [Float](repeating: 1.0 / Float(compression),
                             count: Int(compression))
        
        let downSampledLength = inputSignal.count / compression
        
        var downSampledData = [Float](repeating: 0.0,
                                      count: downSampledLength)
        
        vDSP_desamp(processingBuffer,
                    vDSP_Stride(compression),
                    filter,
                    &downSampledData,
                    vDSP_Length(downSampledLength),
                    vDSP_Length(compression))
        
        return downSampledData
    }
}
