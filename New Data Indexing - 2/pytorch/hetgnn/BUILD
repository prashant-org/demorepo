# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

load("@rules_python//python:defs.bzl", "py_test", "py_library")
load("@pip_deps//:requirements.bzl", "requirement")

py_library(
    name = "example_torch_hetgnn",
    srcs = [
        "args.py",
        "conftest.py",
        "evaluation.py",
        "model.py",
        "main.py",
        "sampler.py",
    ],
    deps = [
        "//src/python/deepgnn/graph_engine/backends:graph_engine_backends",
        "//src/python/deepgnn/graph_engine/snark:graph_engine_snark",
        "//src/python/deepgnn/graph_engine/data:graph_engine_data",
        "//src/python/deepgnn/pytorch:deepgnn_pytorch",
        "//src/python/deepgnn/pytorch/common:deepgnn_pytorch_common",
        "//src/python/deepgnn/pytorch/encoding:deepgnn_pytorch_encoding",
        "//src/python/deepgnn/pytorch/modeling:deepgnn_pytorch_modeling",
        "//src/python/deepgnn/pytorch/nn:deepgnn_pytorch_nn",
        "//src/python/deepgnn/pytorch/training:deepgnn_pytorch_training",
        "//examples/pytorch:example_torch_tests",
    ],
)

py_test(
    name = "test_model",
    srcs = ["test_model.py"],
    imports = ["../../../src/python/"],
    main = "test_model.py",
    python_version = "PY3",
    srcs_version = "PY3",
    deps = [
        ":example_torch_hetgnn",
        requirement("numpy"),
        requirement("pytest"),
        requirement("scikit-learn"),
        requirement("torch"),
        requirement("fsspec"),
        requirement("transformers"),
        requirement("networkx"),
        requirement("opencensus"),
        requirement("opencensus-context"),
        requirement("opencensus-ext-azure"),
        requirement("azure-datalake-store"),
    ],
)

py_test(
    name = "test_args",
    srcs = ["test_args.py"],
    imports = ["../../../src/python/"],
    main = "test_args.py",
    python_version = "PY3",
    srcs_version = "PY3",
    deps = [
        ":example_torch_hetgnn",
        requirement("horovod"),
        requirement("fsspec"),
        requirement("numpy"),
        requirement("pytest"),
        requirement("scikit-learn"),
        requirement("torch"),
        requirement("networkx"),
        requirement("tensorboard"),
        requirement("transformers"),
        requirement("opencensus"),
        requirement("opencensus-context"),
        requirement("opencensus-ext-azure"),
        requirement("azure-datalake-store"),
    ],
)
