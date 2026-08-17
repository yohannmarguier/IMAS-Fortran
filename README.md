# IMAS-Fortran

This repository contains the Fortran data access library for IMAS. 
It allows to manipulate Fortran data structures that correspond to IDS defined in the 
[IMAS-Data-Dictionary](https://github.com/iterorganization/IMAS-Data-Dictionary).
It relies on the [IMAS-Core](https://github.com/iterorganization/IMAS-Core) library 
to abstract I/O operations from the underlying chosen data storage format. 


## Getting started

The latest build, install and user documentation is available [here](https://imas-fortran.readthedocs.io/en/latest/). 


## Routing through the multiversion shim

`-D AL_USE_MULTIVERSION_SHIM=ON` builds against
[IMAS-Multiversion-DD-Loader](https://github.com/yohannmarguier/IMAS-Multiversion-DD-Loader)
instead of against IMAS-Core directly. The shim re-exports IMAS-Core's public C ABI
symbol for symbol and opens the real IMAS-Core at run time, so no source in this
repository changes and the test suite runs unmodified:

```bash
cmake -B build -D AL_USE_MULTIVERSION_SHIM=ON \
    -D CMAKE_PREFIX_PATH=/path/to/shim/prefix \
    -D AL_BACKEND_HDF5=ON        # IMAS-Core's options are not declared in this mode
                                 # (MDSplus is not available at all — it needs a
                                 #  model target IMAS-Core builds)
cmake --build build -j
ctest --test-dir build --output-on-failure
```

IMAS-Core is still needed to *run*: the shim mirrors its ABI and implements none of
it, so it opens the real one and forwards. The build acquires an IMAS-Core for that
purpose — by the same `AL_DOWNLOAD_DEPENDENCIES` / `AL_DEVELOPMENT_LAYOUT` choice as
every other dependency — builds it under `build/_deps/al-core-runtime-build`, and
never puts it on a link line. To open an IMAS-Core that already exists instead of
building one, point `-D AL_CORE_RUNTIME_LIBRARY=/path/to/libal.so` at the library
itself.

The option defaults to `OFF`, in which case nothing about the build changes.
`common/cmake/ALCore.cmake` binds the target name `al` to the shim; the link line
is untouched. `ctest -R shim-linkage` checks that the built library really does
record the shim as a dependency, and `otool -L`/`ldd` on `libal-fortran-*` shows it
directly.

> **A NAG build silently bypasses the shim.** The NAG branch in `CMakeLists.txt`
> hardcodes `-lal` instead of linking the `al` target, so it links IMAS-Core no
> matter what this option is set to — with no error and no warning. Once the shim
> carries conversion logic, the only symptom is data that was never translated.

See [`docs/adr/0001-multiversion-shim-linkage.md`](docs/adr/0001-multiversion-shim-linkage.md)
for why the target name is retargeted rather than the shim being shipped under
IMAS-Core's own library name.


## Legal

IMAS-Fortran is licensed under [LGPL 3.0](LICENSE.txt). 


## Acknowledgements

Bootstrapped from the UAL's fortraninterface.
