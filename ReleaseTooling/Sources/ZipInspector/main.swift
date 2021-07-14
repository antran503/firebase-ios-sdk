//
// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

import ArgumentParser

/// Usage:
/// swift run zip-inspector artifact1 artifact2
/// Args: artifact1, artifact2
/// Flags: --verbose, --firebase-frameworks-only
/// Options: , --framework-pattern
struct ZipInspector: ParsableCommand {

  static var configuration =
  		CommandConfiguration(abstract: "Generates a configurable diff between two zipped artifacts")

  @Argument(help: "Path to a zipped release artifact.",
            transform: URL.init(fileURLWithPath:))
  var artifact1: URL

  @Argument(help: "Path to a zipped release artifact.",
            transform: URL.init(fileURLWithPath:))
  var artifact2: URL

  @Flag(help: "")
  var verbose: Bool = false

  @Flag(inversion: .prefixedNo)
  var good: Bool = true


  mutating func validate() throws {
    try validateArtifact(artifact1)
    try validateArtifact(artifact2)
  }

  func run() throws {
    self
      .copyArtifacts()
      .unzipArtifacts()
      // Remove .DS_Store
      // Remove framework binaries
      .prepareArtifacts()
      .inspectArtifacts()
      .cleanup()
      .outputLogs()
  }
}

ZipInspector.main()

/*
 // Changelog Updating tool

self
  .updateCHANGELOGs(to: version)
*/
