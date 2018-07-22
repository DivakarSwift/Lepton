//
//  OpenGLRenderer.swift
//  Lepton
//
//  Created by bl4ckra1sond3tre on 2018/6/16.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import OpenGLES
import CoreMedia

private let ATTRIB_VERTEX = 0
private let ATTRIB_TEXTUREPOSITION = 1

public class OpenGLRenderer: Renderer {

    private var context: EAGLContext

    private var textureCache: CVOpenGLESTextureCache?

    private var renderTextureCache: CVOpenGLESTextureCache?

    private var bufferPool: CVPixelBufferPool?

    private var bufferPoolAuxAttributes: NSDictionary?

    private var outputFormatDescription: CMFormatDescription?

    private var program: GLuint = 0

    private var frame: GLint = 0

    private var offscreenBufferHandle: GLuint = 0

    public init?() {
        guard let context = EAGLContext(api: .openGLES2) else {
            return nil
        }

        self.context = context
    }

    deinit {
        deleteBuffers()
    }

    public func prepare(forInputformatDescription inputFormatDescription: CMFormatDescription, ouputRetainedBufferCountHint: Int) {
        // The input and output dimensions are the same. This renderer doesn't do any scaling.
        let dimensions = CMVideoFormatDescriptionGetDimensions(inputFormatDescription)

        deleteBuffers()
        if !initializeBuffers(outputDimensions: dimensions, ratainedBufferCountHint: ouputRetainedBufferCountHint) {
            fatalError("Problem preparing renderer.")
        }
    }

    // MARK: - Renderer

    public var inputPixelFormat: FourCharCode {
        return kCVPixelFormatType_32BGRA
    }

    public func reset() {
        deleteBuffers()
    }

    public func copyRenderedPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
        struct Constant {
            static let squareVertices: [GLfloat] = [
                -1.0, -1.0, // bottom left
                1.0, -1.0, // bottom right
                -1.0, 1.0, // top left
                1.0, -1.0, // top right
            ]

            static let textureVertices: [Float] = [
                0.0, 0.0, // bottom left
                1.0, 0.0, // bottom right
                0.0, 1.0, // top left
                1.0, 1.0, // top right
            ]
        }

        if offscreenBufferHandle == 0 {
            fatalError("Unintialized buffer")
        }

        guard let outputFormatDescription = outputFormatDescription,
            let bufferPool = bufferPool,
            let textureCache = textureCache,
            let renderTextureCache = renderTextureCache else {
            fatalError("outputFormatDescription can't be nil")
        }

        let srcDimensions = CMVideoDimensions(width: Int32(CVPixelBufferGetWidth(pixelBuffer)), height: Int32(CVPixelBufferGetHeight(pixelBuffer)))
        let dstDimensions = CMVideoFormatDescriptionGetDimensions(outputFormatDescription)

        if srcDimensions.width != dstDimensions.width || srcDimensions.height != dstDimensions.height {
            fatalError("Invalid pixel buffer dimensions")
        }

        if CVPixelBufferGetPixelFormatType(pixelBuffer) != kCVPixelFormatType_32BGRA {
            fatalError("Invalid pixel buffer format")
        }

        let oldContext = EAGLContext.current()
        if oldContext !== context {
            if !EAGLContext.setCurrent(context) {
                fatalError("Problem with OpenGL context")
            }
        }

        var err: CVReturn = noErr
        var srcTexture: CVOpenGLESTexture?
        var dstTexture: CVOpenGLESTexture?
        var dstPixelBuffer: CVPixelBuffer?

        bail: do {
            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, GL_TEXTURE_2D.ui, GL_RGBA, srcDimensions.width, srcDimensions.height, GL_BGRA.ui, GL_UNSIGNED_BYTE.ui, 0, &srcTexture)
            guard let srcTexture = srcTexture, err == 0 else {
                print("Error at CVOpenGLESTextureCacheCreateTextureFromImage \(err)")
                break bail
            }

            err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, bufferPool, bufferPoolAuxAttributes, &dstPixelBuffer)
            if err != 0 {
                if err == kCVReturnWouldExceedAllocationThreshold {
                    // Flush the texture cache to potentially release the retained buffers and try again to create a pixel buffer.
                    print("Pool is out of buffer, dropping frame")
                } else {
                    print("Error at CVPixelBufferPoolCreatePixelBufferWithAuxAttributes \(err)")
                }
                break bail
            }
            guard let dstPixelBuffer = dstPixelBuffer else {
                print("Error at CVPixelBufferPoolCreatePixelBufferWithAuxAttributes \(err)")
                break bail
            }

            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, renderTextureCache, dstPixelBuffer, nil, GL_TEXTURE_2D.ui, GL_RGBA, dstDimensions.width, dstDimensions.height, GL_BGRA.ui, GL_UNSIGNED_BYTE.ui, 0, &dstTexture)
            guard let dstTexture = dstTexture, err == 0 else {
                print("Error at CVOpenGLESTextureCacheCreateTextureFromImage \(err)")
                break bail
            }

            glBindFramebuffer(GL_FRAMEBUFFER.ui, offscreenBufferHandle)
            glViewport(0, 0, srcDimensions.width, srcDimensions.height)
            glUseProgram(program)

            // Set up our destination pixel buffer as the framebuffer's render target.
            glActiveTexture(GL_TEXTURE1.ui)
            glBindTexture(CVOpenGLESTextureGetTarget(dstTexture), CVOpenGLESTextureGetName(dstTexture))

            glTexParameteri(GL_TEXTURE_2D.ui, GL_TEXTURE_MIN_FILTER.ui, GL_LINEAR)
            glTexParameteri(GL_TEXTURE_2D.ui, GL_TEXTURE_MAG_FILTER.ui, GL_LINEAR)
            glTexParameteri(GL_TEXTURE_2D.ui, GL_TEXTURE_WRAP_S.ui, GL_CLAMP_TO_EDGE)
            glTexParameteri(GL_TEXTURE_2D.ui, GL_TEXTURE_WRAP_T.ui, GL_CLAMP_TO_EDGE)
            glFramebufferTexture2D(GL_FRAMEBUFFER.ui, GL_COLOR_ATTACHMENT0.ui, CVOpenGLESTextureGetTarget(dstTexture), CVOpenGLESTextureGetName(dstTexture), 0)

            // Render our source pixel buffer
            glActiveTexture(GL_TEXTURE1.ui)
            glBindTexture(CVOpenGLESTextureGetTarget(srcTexture), CVOpenGLESTextureGetName(srcTexture))
            glUniform1i(frame, 1)

            glTexParameteri(GL_TEXTURE_2D.ui, GL_TEXTURE_MIN_FILTER.ui, GL_LINEAR)
            glTexParameteri(GL_TEXTURE_2D.ui, GL_TEXTURE_MAG_FILTER.ui, GL_LINEAR)
            glTexParameteri(GL_TEXTURE_2D.ui, GL_TEXTURE_WRAP_S.ui, GL_CLAMP_TO_EDGE)
            glTexParameteri(GL_TEXTURE_2D.ui, GL_TEXTURE_WRAP_T.ui, GL_CLAMP_TO_EDGE)

            glVertexAttribPointer(GLuint(ATTRIB_VERTEX), 2, GL_FLOAT.ui, 0, 0, Constant.squareVertices)
            glEnableVertexAttribArray(GLuint(ATTRIB_VERTEX))
            glVertexAttribPointer(GLuint(ATTRIB_TEXTUREPOSITION), 2, GL_FLOAT.ui, 0, 0, Constant.textureVertices)
            glEnableVertexAttribArray(GLuint(ATTRIB_TEXTUREPOSITION))

            glDrawArrays(GL_TRIANGLE_STRIP.ui, 0, 4)

            glBindTexture(CVOpenGLESTextureGetTarget(srcTexture), 0)
            glBindTexture(CVOpenGLESTextureGetTarget(dstTexture), 0)

            // Make sure that outstanding GL commands which render to the destination pixel buffer have been submitted.
            // AVAssetWriter, AVSampleBufferDisplayLayer, and GL will block until the rendering is complete when sourcing from this pixel buffer
            glFlush()
        } // bail:

        if oldContext !== context {
            EAGLContext.setCurrent(oldContext)
        }

        return dstPixelBuffer ?? pixelBuffer
    }

    private func initializeBuffers(outputDimensions: CMVideoDimensions, ratainedBufferCountHint: Int) -> Bool {
        var success = true
        let oldContext = EAGLContext.current()

        if oldContext !== context {
            if EAGLContext.setCurrent(context) {
                fatalError("Problem with OpenGL context")
            }
        }

        glDisable(GL_DEPTH_TEST.ui)

        glGenFramebuffers(1, &offscreenBufferHandle)
        glBindFramebuffer(GL_FRAMEBUFFER.ui, offscreenBufferHandle)

        bail: do {
            var err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, context, nil, &textureCache)
            if err != 0 {
                print("Error at CVOpenGLESTextureCacheCreate \(err)")
                success = false
                break bail
            }

            err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, context, nil, &renderTextureCache)
            if err != 0 {
                print("Error at CVOpenGLESTextureCacheCreate \(err)")
                success = false
                break bail
            }

            let attributeLocations: [GLuint] = [
                ATTRIB_VERTEX.ui,
                ATTRIB_TEXTUREPOSITION.ui,
            ]

            let attributeNames: [String] = [
                "position",
                "texturecoordinate",
            ]

            var uniformLocations: [GLint] = []

            let verSource = OpenGLRenderer.readFile("filter.vsh")
            let fragSource = OpenGLRenderer.readFile("filter.fsh")

            // shader program
            glue.create(program: &program,
                        vertSource: verSource,
                        fragSource: fragSource,
                        attributeNames: attributeNames,
                        attributeLocations: attributeLocations,
                        uniformNames: [],
                        uniformLocations: &uniformLocations)

            if program == 0 {
                print("Problem initializing the program.")
                success = false
                break bail
            }

            frame = glue.uniformLocation(program: program, name: "videoframe")

            let maxRetainedBufferCount = ratainedBufferCountHint
            bufferPool = createPixelBufferPoll(width: outputDimensions.width, height: outputDimensions.height, pixelFormat: kCVPixelFormatType_32BGRA, maxBufferCount: Int32(maxRetainedBufferCount))
            guard let bufferPool = bufferPool else {
                print("Problem initializing a buffer pool.")
                success = false
                break bail
            }

            bufferPoolAuxAttributes = createPixelBufferPoolAuxAttribute(maxBufferCount: Int32(maxRetainedBufferCount))
            preallocatePixelBuffers(in: bufferPool, auxAttributes: bufferPoolAuxAttributes!)

            var outputFormatDescription: CMFormatDescription? = nil
            var testPixelBuffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, bufferPool, bufferPoolAuxAttributes, &testPixelBuffer)
            guard let pixelBuffer = testPixelBuffer else {
                print("Problem creating a pixel buffer.")
                success = false
                break bail
            }

            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &outputFormatDescription)
            self.outputFormatDescription = outputFormatDescription
        } // bail:

        guard success else {
            self.deleteBuffers()
            return success
        }

        if oldContext !== context {
            EAGLContext.setCurrent(context)
        }

        return success
    }

    private func deleteBuffers() {
        let oldContext = EAGLContext.current()
        if oldContext !== context {
            if !EAGLContext.setCurrent(context) {
                //NSException(name: .internalInconsistencyException, reason: "Problem with OpenGL context", userInfo: nil)
                return
            }
        }

        if offscreenBufferHandle != 0 {
            glDeleteFramebuffers(1, &offscreenBufferHandle)
            offscreenBufferHandle = 0
        }

        if program != 0 {
            glDeleteProgram(program)
            program = 0
        }

        textureCache = nil
        renderTextureCache = nil
        bufferPool = nil
        bufferPoolAuxAttributes = nil
        outputFormatDescription = nil

        if oldContext !== context {
            EAGLContext.setCurrent(oldContext)
        }
    }

    private class func readFile(_ name: String) -> String {
        let path = Bundle.main.path(forResource: name, ofType: nil)!
        let source = try! String(contentsOfFile: path, encoding: .utf8)
        return source
    }
}
