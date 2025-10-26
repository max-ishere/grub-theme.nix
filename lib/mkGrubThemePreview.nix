{
  grub2,
  xorriso,
  qemu,
  stdenv,
  writeShellScriptBin,
  symlinkJoin,
  lib,
}: {
  name ? "unnamed",
  src,
  menuentries ? [
    {
      name = "Test entry for class OS";
      class = "os";
    }
    {
      name = "Test entry for class Windows";
      class = "windows";
    }
  ],
  resolution ? "1920x1080",
  qemu-system ? "x86_64",
  timeout ? 15,
}: let
  iso = stdenv.mkDerivation {
    name = "preview-${name}-grub-theme";
    inherit src;
    buildInputs = [grub2 xorriso qemu];

    grubCfg = builtins.concatStringsSep "\n" [
      (builtins.concatStringsSep "\n" (builtins.map (entry: ''
          menuentry "${entry.name}" ${lib.optionalString (entry ? class) "--class ${entry.class}"} {
            reboot
          }
        '')
        menuentries))

      # Enables themes
      ''
        insmod all_video
        insmod gfxterm
        insmod png
        insmod tga
        insmod jpeg

        set gfxmode=${resolution}
        terminal_output gfxterm
        set theme=$prefix/themes/${name}/theme.txt
        set timeout=${builtins.toString timeout}
        set timeout_style=menu
      ''
    ];

    buildPhase = let
    in ''
      mkdir "$out"

      # Use a special dir for GRUB configs
      BUILD_DIR="$out/build"

      # Load the theme
      mkdir "$BUILD_DIR/boot/grub/themes/${name}" -p
      cp . "$BUILD_DIR/boot/grub/themes/${name}" -r

      # Generate grub.cfg

      # Autodetect fonts and load them
      find "$BUILD_DIR/boot/grub/themes/${name}" -type f -name "*.pf2" \
        -exec basename {} \; \
        | xargs -I {} echo 'loadfont $prefix/themes/${name}/{}' \
        >> "$BUILD_DIR/boot/grub/grub.cfg"

      # Append the rest of the config
      echo "$grubCfg" >> "$BUILD_DIR/boot/grub/grub.cfg"

      # Generate the ISO
      grub-mkrescue -o "$out/preview-${name}.iso" "$BUILD_DIR"

      # Clear the build artifacts
      rm -r "$BUILD_DIR"
    '';
  };
  startVm = writeShellScriptBin "preview-${name}-grub-theme" ''
    ${qemu}/bin/qemu-system-${qemu-system} -cdrom ${iso}/preview-${name}.iso
  '';
in
  symlinkJoin {
    name = "preview-${name}-grub-theme";
    paths = [iso startVm];
  }
  // {meta = startVm.meta.mainProgram;}
