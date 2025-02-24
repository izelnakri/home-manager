{
  redis = pkgs.dockerTools.buildImage {
    name = "redis";
    tag = "latest";

    # for example's sake, we can layer redis on top of bash or debian
    fromImage = bash;
    # fromImage = debian;

    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      paths = [ pkgs.redis ];
      pathsToLink = [ "/bin" ];
    };

    runAsRoot = ''
      mkdir -p /data
    '';

    config = {
      Cmd = [ "/bin/redis-server" ];
      WorkingDir = "/data";
      Volumes = {
        "/data" = {};
      };
    };
  };

  # busyboxFromDockerHub = pkgs.dockerTools.pullImage {
  #   imageName = "busybox";
  #   imageDigest = "sha256:1b0a26bd07a3d17473d8d8468bea84015e27f87124b283b91d781bce13f61370";
  #   sha256 = "sha256-uSmgXdnRe4xITBv8u5cx0bFpUzzxvN95YfbzUqZXtLI=";
  #   finalImageTag = "1.36.1";
  #   finalImageName = "busybox";
  #   os = "linux";
  #   arch = "x86_64";
  # };

  # dockerImage = pkgs.dockerTools.buildImage {
  #   name = "mycurl";
  #   tag = "0.1.0";
  #   fromImage = busyboxFromDockerHub;
  #   copyToRoot = pkgs.buildEnv {
  #     name = "image-root";
  #     pathsToLink = [ "/bin" ];
  #     paths = [
  #       csource 
  #       pkgs.nano
  #     ];
  #   };
  #   config = {
  #     Cmd = [ "/bin/sh" ];
  #     Env = [];
  #     Volumes = {};
  #   };
  #   created = "now";
  # };

# buildImage {
#   name = "environment-example";
#   copyToRoot = with pkgs.dockerTools; [
#     usrBinEnv
#     binSh
#     caCertificates
#     fakeNss
#   ];
# }
}

# then it is a defaultPackage = dockerImage and run it with
# $ nix build .#packageNmae
# $ docker load < result
# $ docker run --rm -it mycurl:0.1.0
