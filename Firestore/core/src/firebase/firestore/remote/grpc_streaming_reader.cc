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

#include "Firestore/core/src/firebase/firestore/remote/grpc_streaming_reader.h"

#include <chrono>  // NOLINT(build/c++11)
#include <future>  // NOLINT(build/c++11)
#include <utility>

#include "Firestore/core/src/firebase/firestore/util/hard_assert.h"

namespace firebase {
namespace firestore {
namespace remote {

using util::AsyncQueue;
using util::Status;

GrpcStreamingReader::GrpcStreamingReader(
    std::unique_ptr<grpc::ClientContext> context,
    std::unique_ptr<grpc::GenericClientAsyncReaderWriter> call,
    AsyncQueue* worker_queue,
    const grpc::ByteBuffer& request)
    : context_{std::move(context)},
      call_{std::move(call)},
      worker_queue_{worker_queue},
      request_{request} {
}

GrpcStreamingReader::~GrpcStreamingReader() {
  HARD_ASSERT(!completion_,
              "GrpcStreamingReader is being destroyed without proper shutdown");
}

void GrpcStreamingReader::Start(CallbackT callback) {
  callback_ = callback;

  context_->set_initial_metadata_corked(true);
  call_->StartCall(nullptr);

  WriteRequest();
}

void GrpcStreamingReader::WriteRequest() {
  SetCompletion([this](const GrpcCompletion*) { Read(); });
  *completion_->message() = std::move(request_);

  call_->WriteLast(*completion_->message(), grpc::WriteOptions{},
                   completion_);
}

void GrpcStreamingReader::Read() {
  SetCompletion([this](const GrpcCompletion* completion) {
    // Accumulate responses
    responses_.push_back(*completion->message());
    Read();
  });

  call_->Read(completion_->message(), completion_);
}

void GrpcStreamingReader::Cancel() {
  if (!completion_) {
    // Nothing to cancel.
    return;
  }

  context_->TryCancel();
  FastFinishCompletion();

  SetCompletion([this](const GrpcCompletion*) {
    // Deliberately ignored
  });
  call_->Finish(completion_->status(), completion_);
  FastFinishCompletion();
}

void GrpcStreamingReader::FastFinishCompletion() {
  completion_->Cancel();
  // This function blocks.
  completion_->WaitUntilOffQueue();
  completion_ = nullptr;
}

void GrpcStreamingReader::OnOperationFailed() {
  SetCompletion([this](const GrpcCompletion* completion) {
    HARD_ASSERT(callback_, "GrpcStreamingReader finished without a callback ");
    callback_(Status::FromGrpcStatus(*completion->status()), responses_);
  });
  call_->Finish(completion_->status(), completion_);
}

void GrpcStreamingReader::SetCompletion(const OnSuccess& on_success) {
  // Can't move into lambda until C++14.
  GrpcCompletion::Callback decorated =
      [this, on_success](bool ok, const GrpcCompletion* completion) {
        completion_ = nullptr;

        if (ok) {
          on_success(completion);
        } else {
          OnOperationFailed();
        }
      };

  HARD_ASSERT(!completion_,
              "Creating a new completion before the previous one is done");
  completion_ = new GrpcCompletion{worker_queue_, std::move(decorated)};
}

GrpcStreamingReader::MetadataT GrpcStreamingReader::GetResponseHeaders() const {
  return context_->GetServerInitialMetadata();
}

}  // namespace remote
}  // namespace firestore
}  // namespace firebase
