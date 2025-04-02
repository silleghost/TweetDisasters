let
  nixpkgs = import <nixpkgs> {
    config = {
      allowUnfree = true;
    };
    overlays = [
      (final: prev: {
        python312 = prev.python312.override {
          packageOverrides = final: prevPy: {
            triton-bin = prevPy.triton-bin.overridePythonAttrs (oldAttrs: {
              postFixup = ''
                chmod +x "$out/${prev.python312.sitePackages}/triton/backends/nvidia/bin/ptxas"
                substituteInPlace $out/${prev.python312.sitePackages}/triton/backends/nvidia/driver.py \
                  --replace \
                    'return [libdevice_dir, *libcuda_dirs()]' \
                    'return [libdevice_dir, "${prev.addDriverRunpath.driverLink}/lib", "${prev.cudaPackages.cuda_cudart}/lib/stubs/"]'
              '';
            });
          };
        };
        python312Packages = final.python312.pkgs;
      })
    ];
  };
in
nixpkgs.mkShell {
  name = "cuda-env-shell";
  buildInputs = with nixpkgs; [
    git
    gitRepo
    gnupg
    autoconf
    curl
    procps
    gnumake
    util-linux
    m4
    gperf
    unzip
    cudatoolkit
    linuxPackages.nvidia_x11
    libGLU
    libGL
    xorg.libXi
    xorg.libXmu
    freeglut
    xorg.libXext
    xorg.libX11
    xorg.libXv
    xorg.libXrandr
    zlib
    ncurses5
    stdenv.cc
    binutils
    python312Packages.pytorch-bin
    python312Packages.huggingface-hub
    python312Packages.transformers
    python312Packages.tokenizers
    python312Packages.transformers
    python312Packages.pandas
    python312Packages.peft
    python312Packages.tqdm
    python312Packages.pyarrow
    python312Packages.jupyterlab
    python312Packages.nltk
    python312Packages.scikit-learn

  ];
  shellHook = ''
    export CUDA_PATH=${nixpkgs.cudatoolkit}
    export LD_LIBRARY_PATH=/usr/lib/wsl/lib:${nixpkgs.linuxPackages.nvidia_x11}/lib:${nixpkgs.ncurses5}/lib
    export EXTRA_CCFLAGS="-I/usr/include"
    export EXTRA_LDFLAGS="-L/lib -L${nixpkgs.linuxPackages.nvidia_x11}/lib"
  '';
}
