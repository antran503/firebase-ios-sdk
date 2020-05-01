/*
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

protocol GitDiffCommandOutputParserProtocol {
  func parseDiff() throws -> FileDiff
}

class GitDiffCommandOutputParser: GitDiffCommandOutputParserProtocol {
  let string: String
  init(string: String) {
    self.string = string
  }

  func parseDiff() throws -> FileDiff {
    let scanner = Scanner(string: string)
    scanner.charactersToBeSkipped = nil

    let prefix = try scanner.scanUpToPaths()
    let (oldPath, newPath) = try scanner.scanPaths()

    return FileDiff(oldPath: oldPath, newPath: newPath, lines: [])
  }
}

private extension Scanner {
  func scanUpToPaths() throws -> String {
    let scanLocation = self.scanLocation
    guard let result = compatibilityScanUpTo("diff --git a/") else {
      return ""
    }

    guard !isAtEnd else {
      throw GitDiffCommandOutputParser.ParserError
        .diffStartNotFound(searchStartLocation: scanLocation)
    }

    return result
  }

  func scanPaths() throws -> (oldPath: String, newPath: String) {
    // Expect string like:
    // `diff --git a/<oldPath> b/<newPath>`

    var scanLocation = self.scanLocation
    guard scanString("diff --git a/", into: nil) else {
      throw GitDiffCommandOutputParser.ParserError
        .diffStartNotFound(searchStartLocation: scanLocation)
    }

    scanLocation = self.scanLocation
    guard let oldPath = compatibilityScanUpTo(" b/") else {
      throw GitDiffCommandOutputParser.ParserError
        .oldFilePathNotFound(searchStartLocation: scanLocation)
    }

    // Skip to new path start
    scanLocation = self.scanLocation
    guard scanString(" b/", into: nil) else {
      throw GitDiffCommandOutputParser.ParserError
        .newFilePathNotFound(searchStartLocation: scanLocation)
    }

    scanLocation = self.scanLocation
    guard let newPath = compatibilityScanUpTo("\n") else {
      throw GitDiffCommandOutputParser.ParserError
        .newFilePathNotFound(searchStartLocation: scanLocation)
    }

    return (oldPath, newPath)
  }

  func compatibilityScanUpTo(_ substring: String) -> String? {
    if #available(OSX 10.15, *) {
      return scanUpToString(substring)
    } else {
      var resultNSString: NSString?
      guard scanUpTo(substring, into: &resultNSString) else {
        return nil
      }

      guard let unwrappedResult = resultNSString else {
        return nil
      }

      return String(unwrappedResult)
    }
  }
}

extension GitDiffCommandOutputParser {
  enum ParserError: Error {
    case diffStartNotFound(searchStartLocation: Int)
    case oldFilePathNotFound(searchStartLocation: Int)
    case newFilePathNotFound(searchStartLocation: Int)
  }
}
