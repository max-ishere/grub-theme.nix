{
  grub2,
  xorriso,
  qemu,
  stdenv,
  writeText,
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
}:
stdenv.mkDerivation {
  name = "preview-${name}-grub-theme";
  inherit src;
  buildInputs = [grub2 xorriso qemu];

  buildPhase = let
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
  in ''
    mkdir $out

    # Use a special dir for GRUB configs
    BUILD_DIR=$out/build

    # Load the theme
    mkdir $BUILD_DIR/boot/grub/themes/${name} -p
    cp . $BUILD_DIR/boot/grub/themes/${name} -r

    # Generate grub.cfg

    # Autodetect fonts and load them
    pushd $BUILD_DIR/boot/grub/themes/${name}
      find -type f -name "*.pf2" \
        -exec basename {} \; \
        | xargs -I {} echo 'loadfont $prefix/themes/${name}/{}' \
        >> $BUILD_DIR/boot/grub/grub.cfg
    popd

    # Append the rest of the config
    echo '${grubCfg}' >> $BUILD_DIR/boot/grub/grub.cfg

    # Generate the ISO
    ${grub2}/bin/grub-mkrescue -o $out/preview-${name}.iso $BUILD_DIR

    # Clear the build artifacts
    rm -r $BUILD_DIR

    # Create a convinience run script
    mkdir $out/bin
    cat <<EOF >$out/bin/preview-${name}-grub-theme
      #!/usr/bin/env sh
      ${qemu}/bin/qemu-system-${qemu-system} -cdrom $out/preview-${name}.iso
    EOF
    chmod +x $out/bin/preview-${name}-grub-theme
  '';
}
