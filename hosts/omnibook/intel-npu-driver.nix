{
  lib,
  stdenv,
  udev,
  openssl,
  boost,
  cmake,
  git,
  level-zero,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "intel-npu-driver";
  version = "1.24.0";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "linux-npu-driver";
    tag = "v${version}";
    fetchSubmodules = true;
    hash = "sha256-pnQ4OV+7bKivhS5lVmdz5Zb9kqaSJK0eK0lK+68wzYU=";
  };

  buildInputs = [
    udev
    openssl
    boost
    level-zero # NOTE: Maybe make unstable.level-zero here
  ];

  nativeBuildInputs = [
    cmake
  ];

  outputs = [
    "out"
    "validation"
    "firmware"
  ];

  postPatch = ''
    rm -rf third_party/level-zero
    rm third_party/cmake/level-zero.cmake
    rm third_party/cmake/FindLevelZero.cmake
    substituteInPlace third_party/CMakeLists.txt --replace-fail \
      "include(cmake/level-zero.cmake)" \
      ""
    substituteInPlace third_party/level-zero-npu-extensions/ze_graph_ext.h --replace-fail \
    "#include \"ze_api.h\"" \
    "#include <level_zero/ze_api.h>"
    substituteInPlace validation/{kmd-test,umd-test}/CMakeLists.txt --replace-fail \
      "COMPONENT validation-npu" \
      "DESTINATION $validation/bin COMPONENT validation-npu"
    substituteInPlace firmware/CMakeLists.txt --replace-fail \
      "DESTINATION /lib/firmware/updates/intel/vpu/" \
      "DESTINATION $firmware/lib/firmware/intel/vpu/"
  '';

  installPhase = ''
    cmake --install . --component level-zero-npu
    cmake --install . --component validation-npu
    cmake --install . --component fw-npu
  '';

  meta = {
    homepage = "https://github.com/intel/linux-npu-driver";
    description = "Intel NPU (Neural Processing Unit) Standalone Driver";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ pseudocc ];
  };
}
# NOTE: Old one:
# # TODO: Change it to v1.16
# {
#   lib,
#   stdenv,
#   udev,
#   openssl,
#   boost,
#   cmake,
#   git,
#   level-zero,
#   fetchFromGitHub,
#   ...
# }:
#
# stdenv.mkDerivation rec {
#   pname = "intel-npu-driver";
#   version = "1.19.0";
#
#   src = fetchFromGitHub {
#     owner = "intel";
#     repo = "linux-npu-driver";
#     rev = "v${version}";
#     fetchSubmodules = true;
#     hash = "sha256-7jEiFEivoyxpLmrt81uKRHLOpRUuJ+G8tPH4YF8KtRM=";
#   };
#
#   buildInputs = [
#     udev
#     openssl
#     boost
#     level-zero
#   ];
#
#   nativeBuildInputs = [
#     cmake
#     git
#   ];
#
#   outputs = [
#     "out"
#     "validation"
#   ];
#
#   postPatch = ''
#     for test in kmd-test umd-test; do
#       substituteInPlace validation/$test/CMakeLists.txt --replace \
#         "COMPONENT validation-npu" \
#         "DESTINATION $validation/bin COMPONENT validation-npu"
#     done
#   '';
#
#   installPhase = ''
#     cmake --install . --component level-zero-npu
#     cmake --install . --component validation-npu
#   '';
#
#   meta = {
#     homepage = "https://github.com/intel/linux-npu-driver";
#     description = "Intel NPU (Neural Processing Unit) Standalone Driver";
#     platforms = [ "x86_64-linux" ];
#     license = lib.licenses.mit;
#     maintainers = with lib.maintainers; [ pseudocc ];
#   };
# }
