//
//  main.swift
//  SwiftGodot/Generator
//
//  Created by Miguel de Icaza on 5/20/20.
//  Copyright © 2020-2023 Miguel de Icaza. MIT Licensed
//
import Foundation

var args = CommandLine.arguments

let jsonFile = args.count > 1 ? args [1] : "/Users/miguel/cvs/godot-master/extension_api.json"
var generatorOutput = args.count > 2 ? args [2] : "/Users/miguel/cvs/SwiftGodot-DEBUG"
var docRoot =  args.count > 3 ? args [3] : "/Users/miguel/cvs/godot-master/doc"

let outputDir = args.count > 2 ? args [2] : generatorOutput

// IF we want a single file, or one file per type
var singleFile = args.contains("--singlefile")

if args.count < 2 {
    print ("Usage is: generator path-to-extension-api output-directory doc-directory")
    print ("- path-to-extensiona-ppi is the full path to extension_api.json from Godot")
    print ("- output-directory is where the files will be placed")
    print ("- doc-directory is the Godot documentation resides (godot/doc)")
    print ("Running with Miguel's testing defaults")
}

let jsonData = try! Data(contentsOf: URL(fileURLWithPath: jsonFile))
let jsonApi = try! JSONDecoder().decode(JGodotExtensionAPI.self, from: jsonData)

// Determines whether a built-in type is defined as a structure, this means:
// that it has fields and does not have a "handle" pointer to the native object
var isStructMap: [String:Bool] = [:]

func dropMatchingPrefix (_ enumName: String, _ enumKey: String) -> String {
    let snake = snakeToCamel (enumKey)
    if snake.lowercased().starts(with: enumName.lowercased()) {
        if snake.count == enumName.count {
            return snake
        }
        let ret = String (snake [snake.index (snake.startIndex, offsetBy: enumName.count)...])
        if let f = ret.first {
            if f.isNumber {
                return snake
            }
        }
        if ret == "" {
            return snake
        }
        return ret.first!.lowercased() + ret.dropFirst()
    }
    return snake
}

var globalEnums: [String: JGodotGlobalEnumElement] = [:]

let sharedPrinter: Printer? = singleFile ? Printer() : nil
var coreDefPrinter = sharedPrinter ?? Printer()
coreDefPrinter.preamble()

print ("Running with projectDir=$(projectDir) and output=\(outputDir)")
let globalDocs = loadClassDoc(base: docRoot, name:  "@GlobalScope")
var classMap: [String:JGodotExtensionAPIClass] = [:]
for x in jsonApi.classes {
    classMap [x.name] = x
}

var builtinMap: [String: JGodotBuiltinClass] = [:]
generateEnums(coreDefPrinter, cdef: nil, values: jsonApi.globalEnums, constantDocs: globalDocs?.constants?.constant, prefix: "")

for x in jsonApi.builtinClasses {
    let value = x.members?.count ?? 0 > 0
    isStructMap [String (x.name)] = value
    builtinMap [x.name] = x
}
for x in ["Float", "Int", "float", "int", "Int32", "Bool", "bool"] {
    isStructMap [x] = true
}

var builtinSizes: [String: Int] = [:]
for cs in jsonApi.builtinClassSizes {
    if cs.buildConfiguration == "float_64" {
        for c in cs.sizes {
            builtinSizes [c.name] = c.size
        }
    }
}

let generatedBuiltinDir = outputDir + "/generated-builtin/"
let generatedDir = outputDir + "/generated/"

if singleFile {
    try! FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
} else {
    try! FileManager.default.createDirectory(atPath: generatedBuiltinDir, withIntermediateDirectories: true)
    try! FileManager.default.createDirectory(atPath: generatedDir, withIntermediateDirectories: true)
}

generateBuiltinClasses(values: jsonApi.builtinClasses, outputDir: generatedBuiltinDir, sharedPrinter: sharedPrinter)
generateUtility(values: jsonApi.utilityFunctions, outputDir: generatedBuiltinDir, sharedPrinter: sharedPrinter)
generateClasses (values: jsonApi.classes, outputDir: generatedDir, sharedPrinter: sharedPrinter)

generateCtorPointers (coreDefPrinter)
if let sharedPrinter {
    sharedPrinter.save(outputDir + "/generated.swift")
} else {
    coreDefPrinter.save (generatedBuiltinDir + "/core-defs.swift")
}

//print ("Done")
