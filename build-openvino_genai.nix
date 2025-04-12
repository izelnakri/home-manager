{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  wheel,
}:

buildPythonPackage rec {
  pname = "openvino-genai";
  version = "2025.0.0.0";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-CP3V73yWSArRHBLUct4hrNMjWZlvaaUlkpm1QP66RWA=";
  };

  # do not run tests
  doCheck = false;

  # specific to buildPythonPackage, see its reference
  pyproject = true;

  build-system = [
    setuptools
    wheel
  ];
}
