// Copyright 2020 Google LLC
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

import FirebaseCore
@testable import FirebaseRemoteConfig

import XCTest

class APITestBase: XCTestCase {
  static var useFakeConfig: Bool!
  static var mockedFetch: Bool!
  var app: FirebaseApp!
  var config: RemoteConfig!
  var console: RemoteConfigConsole!
  var fakeConsole: FakeConsole!

  override class func setUp() {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
      APITests.mockedFetch = false
    }
    useFakeConfig = FirebaseApp.app()!.options.projectID == "FakeProject"
  }

  override func setUpWithError() throws {
    try super.setUpWithError()
    app = FirebaseApp.app()
    config = RemoteConfig.remoteConfig(app: app!)
    let settings = RemoteConfigSettings()
    settings.minimumFetchInterval = 0
    config.configSettings = settings

    let jsonData = try JSONSerialization.data(
      withJSONObject: Constants.jsonValue
    )
    guard let jsonValue = String(data: jsonData, encoding: .ascii) else {
      fatalError("Failed to make json Value from jsonData")
    }

    if APITests.useFakeConfig {
      if !APITests.mockedFetch {
        APITests.mockedFetch = true
        config.configFetch = FetchMocks.mockFetch(config.configFetch)
      }
      fakeConsole = FakeConsole()
      config.configFetch.fetchSession = URLSessionMock(with: fakeConsole)

      fakeConsole.config = [Constants.key1: Constants.value1,
                            Constants.jsonKey: jsonValue,
                            Constants.nonJsonKey: Constants.nonJsonValue,
                            Constants.stringKey: Constants.stringValue,
                            Constants.intKey: String(Constants.intValue),
                            Constants.floatKey: String(Constants.floatValue),
                            Constants.decimalKey: String(Constants.decimalValue),
                            Constants.trueKey: String(true),
                            Constants.falseKey: String(false),
                            Constants.dataKey: Constants.dataValue]
    } else {
      console = RemoteConfigConsole()
      console.updateRemoteConfigValue(Constants.obiwan, forKey: Constants.jedi)
    }

    // Uncomment for verbose debug logging.
    // FirebaseConfiguration.shared.setLoggerLevel(FirebaseLoggerLevel.debug)
  }

  override func tearDown() {
    if APITests.useFakeConfig {
      fakeConsole.empty()
    } else {
      console.removeRemoteConfigValue(forKey: Constants.sith)
      console.removeRemoteConfigValue(forKey: Constants.jedi)
    }
    app = nil
    config = nil
    super.tearDown()
  }
}
