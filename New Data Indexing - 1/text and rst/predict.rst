:github_url: https://github.com/google/neural-tangents/tree/main/docs/predict.rst

.. default-role:: code

`nt.predict` -- inference w/ NNGP & NTK
=============================================================

.. automodule:: neural_tangents._src.predict
.. currentmodule:: neural_tangents.predict


Prediction / inference functions
--------------------------------------
Functions to make train/test set predictions given NNGP/NTK kernels or the linearized function.

.. autosummary::
 :toctree: _autosummary

    gradient_descent
    gradient_descent_mse
    gradient_descent_mse_ensemble
    gp_inference


Utilities
--------------------------------------
.. autosummary::
 :toctree: _autosummary

    max_learning_rate


Helper classes
--------------------------------------
Dataclasses and namedtuples used to return predictions.

.. autosummary::
 :toctree: _autosummary

    Gaussian
    ODEState
