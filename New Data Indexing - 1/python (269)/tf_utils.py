# Copyright 2018 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================
"""TensorFlow-related utilities."""

import collections
import copy
import random

import numpy as np
import tensorflow.compat.v2 as tf

from keras import backend
from keras.engine import keras_tensor
from keras.utils import object_identity
from keras.utils import tf_contextlib

# isort: off
from tensorflow.python.framework import ops
from tensorflow.python.util.tf_export import keras_export


@keras_export("keras.utils.set_random_seed", v1=[])
def set_random_seed(seed):
    """Sets all random seeds for the program (Python, NumPy, and TensorFlow).

    You can use this utility to make almost any Keras program fully
    deterministic. Some limitations apply in cases where network communications
    are involved (e.g. parameter server distribution), which creates additional
    sources of randomness, or when certain non-deterministic cuDNN ops are
    involved.

    Calling this utility is equivalent to the following:

    ```python
    import random
    import numpy as np
    import tensorflow as tf
    random.seed(seed)
    np.random.seed(seed)
    tf.random.set_seed(seed)
    ```

    Arguments:
      seed: Integer, the random seed to use.
    """
    if not isinstance(seed, int):
        raise ValueError(
            "Expected `seed` argument to be an integer. "
            f"Received: seed={seed} (of type {type(seed)})"
        )
    random.seed(seed)
    np.random.seed(seed)
    tf.random.set_seed(seed)
    backend._SEED_GENERATOR.generator = random.Random(seed)


def is_tensor_or_tensor_list(v):
    v = tf.nest.flatten(v)
    if v and isinstance(v[0], tf.Tensor):
        return True
    else:
        return False


def get_reachable_from_inputs(inputs, targets=None):
    """Returns the set of tensors/ops reachable from `inputs`.

    Stops if all targets have been found (target is optional).

    Only valid in Symbolic mode, not Eager mode.

    Args:
      inputs: List of tensors.
      targets: List of tensors.

    Returns:
      A set of tensors reachable from the inputs (includes the inputs
      themselves).
    """
    inputs = tf.nest.flatten(inputs, expand_composites=True)
    reachable = object_identity.ObjectIdentitySet(inputs)
    if targets:
        remaining_targets = object_identity.ObjectIdentitySet(
            tf.nest.flatten(targets)
        )
    queue = collections.deque(inputs)

    while queue:
        x = queue.pop()
        if isinstance(x, tuple(_user_convertible_tensor_types)):
            # Can't find consumers of user-specific types.
            continue

        if isinstance(x, tf.Operation):
            outputs = x.outputs[:] or []
            outputs += x._control_outputs
        elif isinstance(x, tf.Variable):
            try:
                outputs = [x.op]
            except AttributeError:
                # Variables can be created in an Eager context.
                outputs = []
        elif tf.is_tensor(x):
            outputs = x.consumers()
        else:
            raise TypeError(
                f"Expected tf.Operation, tf.Variable, or tf.Tensor. "
                f"Received: {x}"
            )

        for y in outputs:
            if y not in reachable:
                reachable.add(y)
                if targets:
                    remaining_targets.discard(y)
                queue.appendleft(y)

        if targets and not remaining_targets:
            return reachable

    return reachable


# This function needs access to private functions of `nest`.


def map_structure_with_atomic(is_atomic_fn, map_fn, nested):
    """Maps the atomic elements of a nested structure.

    Args:
      is_atomic_fn: A function that determines if an element of `nested` is
        atomic.
      map_fn: The function to apply to atomic elements of `nested`.
      nested: A nested structure.

    Returns:
      The nested structure, with atomic elements mapped according to `map_fn`.

    Raises:
      ValueError: If an element that is neither atomic nor a sequence is
        encountered.
    """
    if is_atomic_fn(nested):
        return map_fn(nested)

    # Recursively convert.
    if not tf.nest.is_nested(nested):
        raise ValueError(
            f"Received non-atomic and non-sequence element: {nested} "
            f"of type {type(nested)}"
        )
    if tf.__internal__.nest.is_mapping(nested):
        values = [nested[k] for k in sorted(nested.keys())]
    elif tf.__internal__.nest.is_attrs(nested):
        values = _astuple(nested)
    else:
        values = nested
    mapped_values = [
        map_structure_with_atomic(is_atomic_fn, map_fn, ele) for ele in values
    ]
    return tf.__internal__.nest.sequence_like(nested, mapped_values)


def get_shapes(tensors):
    """Gets shapes from tensors."""
    return tf.nest.map_structure(
        lambda x: x.shape if hasattr(x, "shape") else None, tensors
    )


def convert_shapes(input_shape, to_tuples=True):
    """Converts nested shape representations to desired format.

    Performs:

    TensorShapes -> tuples if `to_tuples=True`.
    tuples of int or None -> TensorShapes if `to_tuples=False`.

    Valid objects to be converted are:
    - TensorShapes
    - tuples with elements of type int or None.
    - ints
    - None

    Args:
      input_shape: A nested structure of objects to be converted to
        TensorShapes.
      to_tuples: If `True`, converts all TensorShape to tuples. Otherwise
        converts all tuples representing shapes to TensorShapes.

    Returns:
      Nested structure of shapes in desired format.

    Raises:
      ValueError: when the input tensor shape can't be converted to tuples, eg
        unknown tensor shape.
    """

    def _is_shape_component(value):
        return value is None or isinstance(value, (int, tf.compat.v1.Dimension))

    def _is_atomic_shape(input_shape):
        # Ex: TensorShape or (None, 10, 32) or 5 or `None`
        if _is_shape_component(input_shape):
            return True
        if isinstance(input_shape, tf.TensorShape):
            return True
        if isinstance(input_shape, (tuple, list)) and all(
            _is_shape_component(ele) for ele in input_shape
        ):
            return True
        return False

    def _convert_shape(input_shape):
        input_shape = tf.TensorShape(input_shape)
        if to_tuples:
            input_shape = tuple(input_shape.as_list())
        return input_shape

    return map_structure_with_atomic(
        _is_atomic_shape, _convert_shape, input_shape
    )


def validate_axis(axis, input_shape):
    """Validate an axis value and returns its standardized form.

    Args:
      axis: Value to validate. Can be an integer or a list/tuple of integers.
        Integers may be negative.
      input_shape: Reference input shape that the axis/axes refer to.

    Returns:
      Normalized form of `axis`, i.e. a list with all-positive values.
    """
    input_shape = tf.TensorShape(input_shape)
    rank = input_shape.rank
    if not rank:
        raise ValueError(
            f"Input has undefined rank. Received: input_shape={input_shape}"
        )

    # Convert axis to list and resolve negatives
    if isinstance(axis, int):
        axis = [axis]
    else:
        axis = list(axis)
    for idx, x in enumerate(axis):
        if x < 0:
            axis[idx] = rank + x

    # Validate axes
    for x in axis:
        if x < 0 or x >= rank:
            raise ValueError(
                "Invalid value for `axis` argument. "
                "Expected 0 <= axis < inputs.rank (with "
                f"inputs.rank={rank}). Received: axis={tuple(axis)}"
            )
    if len(axis) != len(set(axis)):
        raise ValueError(f"Duplicate axis: {tuple(axis)}")
    return axis


class ListWrapper:
    """A wrapper for lists to be treated as elements for `nest`."""

    def __init__(self, list_to_wrap):
        self._list = list_to_wrap

    def as_list(self):
        return self._list


def convert_inner_node_data(nested, wrap=False):
    """Either wraps or unwraps innermost node data lists in `ListWrapper`
    objects.

    Args:
      nested: A nested data structure.
      wrap: If `True`, wrap innermost lists in `ListWrapper` objects. If
        `False`, unwraps `ListWrapper` objects into lists.

    Returns:
      Structure of same type as nested, with lists wrapped/unwrapped.
    """

    def _is_serialized_node_data(nested):
        # Node data can be of form `[layer_name, node_id, tensor_id]` or
        # `[layer_name, node_id, tensor_id, kwargs]`.
        if (
            isinstance(nested, list)
            and (len(nested) in [3, 4])
            and isinstance(nested[0], str)
        ):
            return True
        return False

    def _is_atomic_nested(nested):
        """Returns `True` if `nested` is a list representing node data."""
        if isinstance(nested, ListWrapper):
            return True
        if _is_serialized_node_data(nested):
            return True
        return not tf.nest.is_nested(nested)

    def _convert_object_or_list(nested):
        """Convert b/t `ListWrapper` object and list representations."""
        if wrap:
            if isinstance(nested, ListWrapper):
                return nested
            if _is_serialized_node_data(nested):
                return ListWrapper(nested)
            return nested
        else:
            if isinstance(nested, ListWrapper):
                return nested.as_list()
            return nested

    return map_structure_with_atomic(
        _is_atomic_nested, _convert_object_or_list, nested
    )


def shape_type_conversion(fn):
    """Decorator that handles tuple/TensorShape conversion.

    Used in `compute_output_shape` and `build`.

    Args:
      fn: function to wrap.

    Returns:
      Wrapped function.
    """

    def wrapper(instance, input_shape):
        # Pass shapes as tuples to `fn`
        # This preserves compatibility with external Keras.
        if input_shape is not None:
            input_shape = convert_shapes(input_shape, to_tuples=True)
        output_shape = fn(instance, input_shape)
        # Return shapes from `fn` as TensorShapes.
        if output_shape is not None:
            output_shape = convert_shapes(output_shape, to_tuples=False)
        return output_shape

    return wrapper


def are_all_symbolic_tensors(tensors):
    return all(map(is_symbolic_tensor, tensors))


_user_convertible_tensor_types = set()


def is_extension_type(tensor):
    """Returns whether a tensor is of an ExtensionType.

    github.com/tensorflow/community/pull/269
    Currently it works by checking if `tensor` is a `CompositeTensor` instance,
    but this will be changed to use an appropriate extensiontype protocol
    check once ExtensionType is made public.

    Args:
      tensor: An object to test

    Returns:
      True if the tensor is an extension type object, false if not.
    """
    return isinstance(tensor, tf.__internal__.CompositeTensor)


def is_symbolic_tensor(tensor):
    """Returns whether a tensor is symbolic (from a TF graph) or an eager
    tensor.

    A Variable can be seen as either: it is considered symbolic
    when we are in a graph scope, and eager when we are in an eager scope.

    Args:
      tensor: A tensor instance to test.

    Returns:
      True for symbolic tensors, False for eager tensors.
    """
    if isinstance(tensor, tf.Tensor):
        return hasattr(tensor, "graph")
    elif is_extension_type(tensor):
        component_tensors = tf.nest.flatten(tensor, expand_composites=True)
        return any(hasattr(t, "graph") for t in component_tensors)
    elif isinstance(tensor, tf.Variable):
        # Variables that are output of a Keras Layer in Functional API mode
        # should be considered symbolic.
        # TODO(omalleyt): We need a better way to check this in order to
        # enable `run_eagerly=True` for Models containing Layers that
        # return Variables as outputs.
        return (
            getattr(tensor, "_keras_history", False)
            or not tf.executing_eagerly()
        )
    elif isinstance(tensor, tuple(_user_convertible_tensor_types)):
        tensor = ops.convert_to_tensor_or_composite(tensor)
        return is_symbolic_tensor(tensor)
    else:
        return False


@keras_export("keras.__internal__.utils.register_symbolic_tensor_type", v1=[])
def register_symbolic_tensor_type(cls):
    """Allows users to specify types regarded as symbolic `Tensor`s.

    Used in conjunction with `tf.register_tensor_conversion_function`, calling
    `tf.keras.__internal__.utils.register_symbolic_tensor_type(cls)`
    allows non-`Tensor` objects to be plumbed through Keras layers.

    Example:

    ```python
    # One-time setup.
    class Foo:
      def __init__(self, input_):
        self._input = input_
      def value(self):
        return tf.constant(42.)

    tf.register_tensor_conversion_function(
        Foo, lambda x, *args, **kwargs: x.value())

    tf.keras.__internal__.utils.register_symbolic_tensor_type(Foo)

    # User-land.
    layer = tf.keras.layers.Lambda(lambda input_: Foo(input_))
    ```

    Args:
      cls: A `class` type which shall be regarded as a symbolic `Tensor`.
    """
    global _user_convertible_tensor_types
    if cls not in _user_convertible_tensor_types:
        keras_tensor.register_keras_tensor_specialization(
            cls, keras_tensor.UserRegisteredTypeKerasTensor
        )
    _user_convertible_tensor_types.add(cls)


def type_spec_from_value(value):
    """Grab type_spec without converting array-likes to tensors."""
    if is_extension_type(value):
        return value._type_spec
    # Get a TensorSpec for array-like data without
    # converting the data to a Tensor
    if hasattr(value, "shape") and hasattr(value, "dtype"):
        return tf.TensorSpec(value.shape, value.dtype)
    else:
        return tf.type_spec_from_value(value)


def is_ragged(tensor):
    """Returns true if `tensor` is a ragged tensor or ragged tensor value."""
    return isinstance(
        tensor, (tf.RaggedTensor, tf.compat.v1.ragged.RaggedTensorValue)
    )


def is_sparse(tensor):
    """Returns true if `tensor` is a sparse tensor or sparse tensor value."""
    return isinstance(tensor, (tf.SparseTensor, tf.compat.v1.SparseTensorValue))


def is_tensor_or_variable(x):
    return tf.is_tensor(x) or isinstance(x, tf.Variable)


def is_tensor_or_extension_type(x):
    """Returns true if 'x' is a TF-native type or an ExtensionType."""
    return tf.is_tensor(x) or is_extension_type(x)


def assert_no_legacy_layers(layers):
    """Prevent tf.layers.Layers from being used with Keras.

    Certain legacy layers inherit from their keras analogs; however they are
    not supported with keras and can lead to subtle and hard to diagnose bugs.

    Args:
      layers: A list of layers to check

    Raises:
      TypeError: If any elements of layers are tf.layers.Layers
    """

    # isinstance check for tf.layers.Layer introduces a circular dependency.
    legacy_layers = [l for l in layers if getattr(l, "_is_legacy_layer", None)]
    if legacy_layers:
        layer_str = "\n".join("  " + str(l) for l in legacy_layers)
        raise TypeError(
            f"The following are legacy tf.layers.Layers:\n{layer_str}\n"
            "To use keras as a "
            "framework (for instance using the Network, Model, or Sequential "
            "classes), please use the tf.keras.layers implementation instead. "
            "(Or, if writing custom layers, subclass from tf.keras.layers "
            "rather than tf.layers)"
        )


@tf_contextlib.contextmanager
def maybe_init_scope(layer):
    """Open an `init_scope` if in V2 mode and using the keras graph.

    Args:
      layer: The Layer/Model that is currently active.

    Yields:
      None
    """
    # Don't open an init_scope in V1 mode or when using legacy tf.layers.
    if tf.compat.v1.executing_eagerly_outside_functions() and getattr(
        layer, "_keras_style", True
    ):
        with tf.init_scope():
            yield
    else:
        yield


@tf_contextlib.contextmanager
def graph_context_for_symbolic_tensors(*args, **kwargs):
    """Returns graph context manager if any of the inputs is a symbolic
    tensor."""
    if any(is_symbolic_tensor(v) for v in list(args) + list(kwargs.values())):
        with backend.get_graph().as_default():
            yield
    else:
        yield


def dataset_is_infinite(dataset):
    """True if the passed dataset is infinite."""
    if tf.compat.v1.executing_eagerly_outside_functions():
        return tf.equal(
            tf.data.experimental.cardinality(dataset),
            tf.data.experimental.INFINITE_CARDINALITY,
        )
    else:
        dataset_size = backend.get_session().run(
            tf.data.experimental.cardinality(dataset)
        )
        return dataset_size == tf.data.experimental.INFINITE_CARDINALITY


def get_tensor_spec(t, dynamic_batch=False, name=None):
    """Returns a `TensorSpec` given a single `Tensor` or `TensorSpec`."""

    if isinstance(t, tf.TypeSpec):
        spec = t
    elif is_extension_type(t):
        # TODO(b/148821952): Should these specs have a name attr?
        spec = t._type_spec
    elif hasattr(t, "_keras_history") and hasattr(
        t._keras_history[0], "_type_spec"
    ):
        return t._keras_history[0]._type_spec
    elif isinstance(t, keras_tensor.KerasTensor):
        spec = t.type_spec
    elif hasattr(t, "shape") and hasattr(t, "dtype"):
        spec = tf.TensorSpec(shape=t.shape, dtype=t.dtype, name=name)
    else:
        return None  # Allow non-Tensors to pass through.

    if not dynamic_batch:
        return spec

    shape = spec.shape
    if shape.rank is None or shape.rank == 0:
        return spec

    shape_list = shape.as_list()
    shape_list[0] = None
    # TODO(b/203201161) Remove this deepcopy one type_spec_with_shape has been
    # updated to not mutate spec.
    spec = copy.deepcopy(spec)
    return keras_tensor.type_spec_with_shape(spec, tf.TensorShape(shape_list))


def sync_to_numpy_or_python_type(tensors):
    """Syncs and converts a structure of `Tensor`s to `NumPy` arrays or Python
    scalar types.

    For each tensor, it calls `tensor.numpy()`. If the result is a scalar value,
    it converts it to a Python type, such as a float or int, by calling
    `result.item()`.

    Numpy scalars are converted, as Python types are often more convenient to
    deal with. This is especially useful for bfloat16 Numpy scalars, which don't
    support as many operations as other Numpy values.

    Async strategies (such as `TPUStrategy` and `ParameterServerStrategy`) are
    forced to
    sync during this process.

    Args:
      tensors: A structure of tensors.

    Returns:
      `tensors`, but scalar tensors are converted to Python types and non-scalar
      tensors are converted to Numpy arrays.
    """
    if isinstance(tensors, tf.distribute.experimental.coordinator.RemoteValue):
        tensors = tensors.fetch()

    def _to_single_numpy_or_python_type(t):
        # Don't turn ragged or sparse tensors to NumPy.
        if isinstance(t, tf.Tensor):
            t = t.numpy()
        # Strings, ragged and sparse tensors don't have .item(). Return them
        # as-is.
        if not isinstance(t, (np.ndarray, np.generic)):
            return t
        return t.item() if np.ndim(t) == 0 else t

    return tf.nest.map_structure(_to_single_numpy_or_python_type, tensors)


def _astuple(attrs):
    """Converts the given attrs to tuple non-recursively."""
    cls = type(attrs)
    fields = getattr(cls, "__attrs_attrs__", None)
    if fields is None:
        raise ValueError(f"{cls} is not an attrs-decorated class.")
    values = []
    for field in fields:
        values.append(getattr(attrs, field.name))
    return tuple(values)
