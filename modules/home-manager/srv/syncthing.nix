{config, lib, pkgs, ...}:

{
	options.srv.syncthing = {
		enable = lib.mkEnableOption "Enable syncthing module";

		folders = {
			secret = {
				enable = lib.mkOption {
					default = true;
					example = true;
					description = "Whether to enable secret folder.";
					type = lib.types.bool;
				};
			};
		};
	};

	config = lib.mkIf config.srv.syncthing.enable {
		services.syncthing = {
			enable = true;

			settings = {
				gui = {
					user = "jacek";
					password = "5TDr>k$z!W:MJe2";
				};

				devices = {
					"homeserver" = { id = "RU32KMJ-OW5RQUY-PLNWIKU-W6NOQHW-XHVTXCU-T2XNWOY-CDW77TE-PZKYDAQ"; };
				};

				folders = {
					"Secret" = lib.mkIf config.srv.syncthing.folders.secret.enable {
					        path = "~/Secret";
						devices = [ "homeserver" ];	
					};
				};
			};
		};
	};
}
