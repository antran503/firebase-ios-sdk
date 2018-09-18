/*
 * Copyright 2018 Google
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

#include <memory>
#include <string>

#include "Firestore/core/src/firebase/firestore/auth/token.h"
#include "Firestore/core/src/firebase/firestore/remote/connectivity_monitor.h"
#include "Firestore/core/src/firebase/firestore/remote/grpc_connection.h"
#include "Firestore/core/src/firebase/firestore/util/async_queue.h"
#include "Firestore/core/src/firebase/firestore/util/executor_std.h"
#include "absl/memory/memory.h"
#include "gtest/gtest.h"

namespace firebase {
namespace firestore {
namespace remote {

using auth::Token;
using core::DatabaseInfo;
using model::DatabaseId;
using util::AsyncQueue;
using util::internal::ExecutorStd;
using NetworkStatus = ConnectivityMonitor::NetworkStatus;

namespace {

class MockConnectivityMonitor : public ConnectivityMonitor {
 public:
  MockConnectivityMonitor(AsyncQueue* worker_queue)
      : ConnectivityMonitor{worker_queue} {
    SetInitialStatus(NetworkStatus::Reachable);
  }

  void set_status(NetworkStatus new_status) {
    MaybeInvokeCallbacks(new_status);
  }
};

class ConnectivityObserver : public GrpcStreamObserver {
 public:
  void OnStreamStart() override {
  }
  void OnStreamRead(const grpc::ByteBuffer& message) override {
  }
  void OnStreamError(const util::Status& status) override {
    ++connectivity_change_count;
  }

  int connectivity_change_count() const {
    return connectivity_change_count_;
  }
  int connectivity_change_count_ = 0;
};

}  // namespace

class GrpcConnectionTest : public testing::Test {
 public:
  GrpcConnectionTest()
      : async_queue{absl::make_unique<ExecutorStd>()},
        database_info_{DatabaseId{"foo", "bar"}, "", "", false},
        connectivity_monitor {
    absl::make_unique<MockConnectivityMonitor>(&worker_queue)
  }
} grpc_connection {
  database_info_, &async_queue, grpc_queue_, connectivity_monitor {
  }

 private:
  DatabaseInfo database_info_;
  grpc::CompletionQueue grpc_queue_;

 public:
  AsyncQueue worker_queue;
  std::unique_ptr<MockConnectivityMonitor> connectivity_monitor;
  GrpcConnection grpc_connection;
};

TEST_F(GrpcConnectionTest, GrpcCallsNoticeChangeInConnectivity) {
  ConnectivityObserver observer;
  auto stream = grpc_connection.CreateStream("", Token{}, &observer);
  EXPECT_EQ(observer.connectivity_change_count(), 0);

  worker_queue.EnqueueBlocking(
      [&] { connectivity_monitor.set_status(NetworkStatus::Unreachable); });
  EXPECT_EQ(observer.connectivity_change_count(), 1);

  worker_queue.EnqueueBlocking(
      [&] { connectivity_monitor.set_status(NetworkStatus::Unreachable); });
  EXPECT_EQ(observer.connectivity_change_count(), 1);

  worker_queue.EnqueueBlocking(
      [&] { connectivity_monitor.set_status(NetworkStatus::Reachable); });
  EXPECT_EQ(observer.connectivity_change_count(), 2);

  worker_queue.EnqueueBlocking([&] {
    connectivity_monitor.set_status(NetworkStatus::ReachableViaCellular);
  });
  EXPECT_EQ(observer.connectivity_change_count(), 3);
}

}  // namespace remote
}  // namespace firestore
}  // namespace firebase
