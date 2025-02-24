#   virtualisation.arion.projects.gitea.settings.services = {
#     server = {
#       service = {
#         ports = [
#           "127.0.0.1:${cfg.port}:3000"
#         ];
#         image = cfg.giteaImage;
#         restart = "always";
#         useHostStore = true;
#         volumes = [
#           "${cfg.dataVolume}:/data"
#           "/etc/timezone:/etc/timezone:ro"
#           "/etc/localtime:/etc/localtime:ro"
#         ];
#         environment = {
#           USER_UID = "1000";
#           USER_GID = "1000";
#         };
#       };
#     };
#   };
# };


# cfg.giteaImage is:
# gitea = {
#   inherit domain;
#   enable = true;
#   dataVolume = "/containers/data/gitea";
#   giteaImage = "gitea/gitea:1.20";
#   port = 8546;
# };
