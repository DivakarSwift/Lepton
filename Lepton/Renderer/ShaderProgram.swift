//
//  ShaderProgram.swift
//  Lepton
//
//  Created by bl4ckra1sond3tre on 2018/6/17.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import OpenGLES

struct glue {

    /// Compile a shader from the provided source(s)
    ///
    /// - Parameters:
    ///   - shader: shader
    ///   - target: shader type
    ///   - count: shader count
    ///   - sources: shader source(s)
    /// - Returns: Status
    static func compile(shader: inout GLuint,
                        target: GLenum,
                        count: GLsizei,
                        sources: UnsafePointer<UnsafePointer<GLchar>?>) -> GLint {
        return glueCompileShader(target, count, sources, &shader)
    }

    /// Link a program with all currently attached shaders
    ///
    /// - Parameter program: Program
    /// - Returns: Status
    static func link(program: GLuint) -> GLint {
        return glueLinkProgram(program)
    }

    /// Link a program with all currently attached shaders
    ///
    /// - Parameter program: Program
    /// - Returns: Status
    static func validate(program: GLuint) -> GLint {
        return glueValidateProgram(program)
    }

    /// Return named uniform location after linking
    ///
    /// - Parameters:
    ///   - program: Program
    ///   - name: Uniform name
    /// - Returns: Location
    static func uniformLocation(program: GLuint, name: String) -> GLint {
        return glueGetUniformLocation(program, name)
    }

    /// Convenience wrapper that compiles, links, enumerates uniforms and attributes
    ///
    /// - Parameters:
    ///   - program: Program
    ///   - vertSource: Vert source
    ///   - fragSource: Frag source
    ///   - attributeNames: Attribute names
    ///   - attributeLocations: Attribute locations
    ///   - uniformName: Uniform name
    ///   - uniformNames: Uniform names
    ///   - uniformLocations: Uniform locations
    /// - Returns: Status
    @discardableResult
    static func create(program: inout GLuint,
                       vertSource: UnsafePointer<GLchar>?,
                       fragSource: UnsafePointer<GLchar>?,
                       attributeNames: [String],
                       attributeLocations: [GLuint],
                       uniformNames: [String],
                       uniformLocations: inout [GLint]) -> GLint {
        return glueCreateProgram(vertSource,
                                 fragSource,
                                 attributeNames,
                                 attributeLocations,
                                 uniformNames,
                                 &uniformLocations,
                                 &program)
    }
}

extension FourCharCode: ExpressibleByStringLiteral {

    public init(stringLiteral value: String.StringLiteralType) {
        if value.utf16.count != 4 {
            fatalError("FourCharCode length must be 4!")
        }
        var code: FourCharCode = 0
        for char in value.utf16 {
            if char > 0xFF {
                fatalError("FourCharCode must contain only ASCII characters!")
            }
            code = (code << 8) + FourCharCode(char)
        }
        self = code
    }
}

extension Int {
    var i: Int32 {
        return Int32(self)
    }

    var ui: UInt32 {
        return UInt32(self)
    }
}

extension Int32 {
    var ui: UInt32 {
        return UInt32(self)
    }

    var l: Int {
        return Int(self)
    }
}

extension UInt32 {
    var i: Int32 {
        return Int32(self)
    }
}

/// Compile a shader from the provided source(s)
///
/// - Parameters:
///   - target: shader type
///   - count: shader count
///   - sources: shader source(s)
///   - shader: shader
/// - Returns: Status
func glueCompileShader(_ target: GLenum,
                       _ count: GLsizei,
                       _ sources: UnsafePointer<UnsafePointer<GLchar>?>,
                       _ shader: inout GLuint) -> GLint {
    var status: GLint = 0

    shader = glCreateShader(target)
    glShaderSource(shader, count, sources, nil)
    glCompileShader(shader)

#if DEBUG
    var logLength: GLint = 0
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH.ui, &logLength)
    if logLength > 0 {
        let log = UnsafeMutablePointer<GLchar>.allocate(capacity: logLength.l)
        glGetShaderInfoLog(shader, logLength, &logLength, log)
        log.deallocate()
    }
#endif

    glGetShaderiv(shader, GL_COMPILE_STATUS.ui, &status)
    if status == 0 {
        print("Failed to compile shader:")
        for i in 0..<count.l {
            print(String(format: "%s", OpaquePointer(sources[i]!)))
        }
    }

    return status
}

/// Link a program with all currently attached shaders
///
/// - Parameter program: Program
/// - Returns: Status
func glueLinkProgram(_ program: GLuint) -> GLint {
    var status: GLint = 0

    glLinkProgram(program)

#if DEBUG
    var logLength: GLint = 0
    glGetProgramiv(program, GL_INFO_LOG_LENGTH.ui, &logLength)
    if logLength > 0 {
        let log = UnsafeMutablePointer<GLchar>.allocate(capacity: logLength.l)
        glGetProgramInfoLog(program, logLength, &logLength, log)
        print(String(format: "Program link log: %s", OpaquePointer(log)))
        log.deallocate()
    }
#endif

    glGetProgramiv(program, GL_LINK_STATUS.ui, &status)
    if status == 0 {
        print("Failed to link program \(program)")
    }

    return status
}

/// Validate a program (for i.e. inconsistent samplers)
///
/// - Parameter program: Program
/// - Returns: Status
func glueValidateProgram(_ program: GLuint) -> GLint {
    var status: GLint = 0

    glValidateProgram(program)

#if DEBUG
    var logLength: GLint = 0
    glGetProgramiv(program, GL_INFO_LOG_LENGTH.ui, &logLength)
    if logLength > 0 {
        let log = UnsafeMutablePointer<GLchar>.allocate(capacity: logLength.l)
        glGetProgramInfoLog(program, logLength, &logLength, log)
        print(String(format: "Program validate log: %s", OpaquePointer(log)))
        log.deallocate()
    }
#endif

    glGetProgramiv(program, GL_VALIDATE_STATUS.ui, &status)
    if status == 0 {
        print("Failed to validate program \(program)")
    }

    return status
}

/// Return named uniform location after linking
///
/// - Parameters:
///   - program: Program
///   - name: Uniform name
/// - Returns: Location
func glueGetUniformLocation(_ program: GLuint, _ name: String) -> GLint {
    return glGetUniformLocation(program, name)
}

/// Convenience wrapper that compiles, links, enumerates uniforms and attributes
///
/// - Parameters:
///   - vertSource: Vert source
///   - fragSource: Frag source
///   - attributeName: Attribute name
///   - attributeNames: Attribute names
///   - attributeLocations: Attribute locations
///   - uniformNames: Uniform names
///   - uniformLocations: Uniform locations
///   - program: Program
/// - Returns: Status
func glueCreateProgram(_ vertSource: UnsafePointer<GLchar>?,
                       _ fragSource: UnsafePointer<GLchar>?,
                       _ attributeNames: [String],
                       _ attributeLocations: [GLuint],
                       _ uniformNames: [String],
                       _ uniformLocations: inout [GLint],
                       _ program: inout GLuint) -> GLint {

    var vertShader: GLuint = 0, fragShader: GLuint = 0, prog: GLuint = 0, status: GLint = 1

    // Create shader program
    prog = glCreateProgram()

    // Create and compile vertex shader
    var vert = vertSource
    status *= glueCompileShader(GL_VERTEX_SHADER.ui, 1, &vert, &vertShader)

    // Create and compile fragment shader
    var frag = fragSource
    status *= glueCompileShader(GL_FRAGMENT_SHADER.ui, 1, &frag, &fragShader)

    // Attach vertex shader to program
    glAttachShader(prog, vertShader)

    // Attach fragment shader to program
    glAttachShader(prog, fragShader)

    // Bind attribute locations
    // This needs to be done prior to linking
    for i in 0..<attributeNames.count {
        if !attributeNames[i].isEmpty {
            glBindAttribLocation(prog, attributeLocations[i], attributeNames[i])
        }
    }

    // Link program
    status *= glueLinkProgram(prog)

    // Get locations of uniforms
    if status != 0 {
        for i in 0..<uniformNames.count {
            if !uniformNames[i].isEmpty {
                uniformLocations[i] = glueGetUniformLocation(prog, uniformNames[i])
            }
        }
        program = prog
    }

    // Release vertex and fragment shaders
    if vertShader != 0 {
        glDeleteShader(vertShader)
    }
    if fragShader != 0 {
        glDeleteShader(fragShader)
    }

    return status
}
