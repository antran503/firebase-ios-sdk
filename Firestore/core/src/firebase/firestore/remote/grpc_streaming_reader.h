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

#ifndef FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_REMOTE_GRPC_STREAMING_READER_H_
#define FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_REMOTE_GRPC_STREAMING_READER_H_

#include <functional>
#include <map>
#include <memory>
#include <vector>

#include "Firestore/core/src/firebase/firestore/remote/grpc_completion.h"
#include "Firestore/core/src/firebase/firestore/util/async_queue.h"
#include "Firestore/core/src/firebase/firestore/util/status.h"
#include "grpcpp/client_context.h"
#include "grpcpp/generic/generic_stub.h"
#include "grpcpp/support/byte_buffer.h"

namespace firebase {
namespace firestore {
namespace remote {

class GrpcStreamingReader {
 public:
  using MetadataT = std::multimap<grpc::string_ref, grpc::string_ref>;
  using CallbackT = std::function<void(const util::Status&, const std::vector<grpc::ByteBuffer>&)>;

  GrpcStreamingReader(std::unique_ptr<grpc::ClientContext> context,
             std::unique_ptr<grpc::GenericClientAsyncReaderWriter> call,
             util::AsyncQueue* firestore_queue,
             const grpc::ByteBuffer& message);
  ~GrpcStreamingReader();

  void Start(CallbackT callback);

  void Cancel();

  /**
   * Returns the metadata received from the server.
   *
   * Can only be called once the stream has opened.
   */
  MetadataT GetResponseHeaders() const;

 private:
  void WriteRequest();
  void Read();

  void OnOperationFailed();

  using OnSuccess = std::function<void(const GrpcCompletion*)>;
  void SetCompletion(const OnSuccess& callback);
  void FastFinishCompletion();

  std::unique_ptr<grpc::ClientContext> context_;
  std::unique_ptr<grpc::GenericClientAsyncReaderWriter> call_;

  util::AsyncQueue* worker_queue_ = nullptr;

  // There is never more than a single pending completion; the full chain is:
  // write -> read -> [read...] -> finish
  GrpcCompletion* completion_ = nullptr;

  CallbackT callback_;
  grpc::ByteBuffer request_;
  std::vector<grpc::ByteBuffer> responses_;
};

}  // namespace remote
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_REMOTE_GRPC_STREAMING_READER_H_
