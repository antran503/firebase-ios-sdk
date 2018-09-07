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

#ifndef FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_REMOTE_GRPC_UNARY_CALL_H_
#define FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_REMOTE_GRPC_UNARY_CALL_H_

#include <functional>
#include <map>
#include <memory>
#include <queue>
#include <string>
#include <utility>
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

class GrpcUnaryCall {
 public:
  using MetadataT = std::multimap<grpc::string_ref, grpc::string_ref>;
  using CallbackT = std::function<void (const grpc::ByteBuffer&, const util::Status&)>;

  GrpcUnaryCall(std::unique_ptr<grpc::ClientContext> context,
             std::unique_ptr<grpc::GenericClientAsyncResponseReader> call,
             const grpc::ByteBuffer& message,
             util::AsyncQueue* worker_queue);
  ~GrpcUnaryCall();

  void Start(CallbackT callback);
  void Cancel();

  MetadataT GetResponseHeaders() const;

 private:
  std::unique_ptr<grpc::ClientContext> context_;
  std::unique_ptr<grpc::GenericClientAsyncResponseReader> call_;
  grpc::ByteBuffer message_;
  
  util::AsyncQueue* worker_queue_ = nullptr;

  GrpcCompletion* finish_completion_;
  CallbackT callback_;
};

}  // namespace remote
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_REMOTE_GRPC_UNARY_CALL_H_
