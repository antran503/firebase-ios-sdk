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
  func parseDiff() throws -> Diff
}

class GitDiffCommandOutputParser: GitDiffCommandOutputParserProtocol {
  let string: String
  init(string: String) {
    self.string = string
  }

  func parseDiff() throws -> Diff {
    if #available(OSX 10.15, *) {
      let scanner = Scanner(string: string)
      scanner.charactersToBeSkipped = nil
      _ = try scanner.scanUpToPaths()
      let (oldPath, newPath) = try scanner.scanPaths()

      // Scan to the first chunk diff.
      var allDiffLines: [FileDiff.Line] = []
      while let lines = scanner.scanChunkDiffLines() {
        allDiffLines += lines
      }

      let file = File(path: newPath, diff: FileDiff(oldPath: oldPath, newPath: newPath, lines: allDiffLines))
      return Diff(files: [file])
    } else {
      throw GitDiffCommandOutputParser.ParserError.unsupportedOSVersion
    }
  }
}

@available(OSX 10.15, *)
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

  func scanChunkDiffLines() -> [FileDiff.Line]? {
    guard let _ = scanUpToChunkSeparator(), let _ = scanChunkSeparator() else {
      return nil
    }

    let diffLines = scanUpToChunkSeparator() ?? ""
    return FileDiff.Line.lines(diffContent: diffLines)
  }

  func scanUpToChunkSeparator(resultPrefix: String = "") -> String? {
    // "@@ -<1st_removed_line>,<number_of_removed_lines> +<1st_added_line>,<number_of_added_lines>"
    // e.g. "@@ -1,5 +1,5 @@"

    let chunkSeparatorPrefix = "@@ -"
    let result = resultPrefix + (compatibilityScanUpTo(chunkSeparatorPrefix) ?? "")

    guard !isAtEnd else {
      return result
    }

    let potentialStartLocation = scanLocation

    guard let _ = scanChunkSeparator() else {
      scanLocation = potentialStartLocation + chunkSeparatorPrefix.count
      return scanUpToChunkSeparator(resultPrefix: result + chunkSeparatorPrefix)
    }

    // Set location to
    scanLocation = potentialStartLocation
    return result
  }

  func scanChunkSeparator()
    -> (removed: CountableClosedRange<Int>, added: CountableClosedRange<Int>)? {
    guard
      let _ = compatibilityScanString("@@ -"),
      let firstRemovedLine = scanInt(),
      let _ = compatibilityScanString(","),
      let removedLineCount = scanInt(),
      let _ = compatibilityScanString(" +"),
      let firstAddedLine = scanInt(),
      let _ = compatibilityScanString(","),
      let addedLineCount = scanInt(),
      let suffix = scanUpToCharacters(from: .newlines),
      let _ = scanCharacters(from: .newlines)
    else {
      return nil
    }
    return (firstRemovedLine ... firstRemovedLine + removedLineCount,
            firstAddedLine ... firstAddedLine + addedLineCount)
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

  func compatibilityScanString(_ searchString: String) -> String? {
    if #available(OSX 10.15, *) {
      return scanString(searchString)
    } else {
      var resultNSString: NSString?
      guard scanString(searchString, into: &resultNSString) else {
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
    case chunkHeaderNotFound
    case unsupportedOSVersion
  }
}

extension FileDiff.Line {
  static func lines(diffContent: String, skipUnmodified: Bool = true) -> [FileDiff.Line] {
    // Expected string:
    //
    // /// xcodebuild, etc). Intentionally empty, this enum is used as a namespace.
    // -internal enum Shell {}
    // +public enum Shell {}
    //
    //  extension Shell {

    return diffContent.split(separator: "\n").compactMap { line in
      if line.hasPrefix("+") {
        return FileDiff.Line(type: .added, content: String(line.suffix(line.count - 1)))
      } else if line.hasPrefix("-") {
        return FileDiff.Line(type: .removed, content: String(line.suffix(line.count - 1)))
      } else if line.hasPrefix(" ") {
        return skipUnmodified ? nil : FileDiff
          .Line(type: .unmodified, content: String(line.suffix(line.count - 1)))
      } else {
        // Actually should never go here.
        return nil
      }
    }
  }
}
