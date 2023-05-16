//
//  UtilityGen.swift
//  Generator
//
//  Created by Miguel de Icaza on 5/14/23.
//

import Foundation

func generateUtility(values: [JGodotUtilityFunction], outputDir: String) {
    let p = Printer ()
    p.preamble()
    defer {
        p.save (outputDir + "utility.swift")
    }
    
    let docClass = loadClassDoc(base: docRoot, name: "@GlobalScope")
    let emptyUsedMethods = Set<String>()
    
    p ("public class GD") {
        for method in values {
            // We ignore the request for virtual methods, should not happen for these
            
            _ = methodGen (p, method: method, className: "Godot", cdef: nil, docClass: docClass, usedMethods: emptyUsedMethods, kind: .utility)
            
        }
    }
}
