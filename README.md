# **pytaglib** – TagLib bindings for Python

## Overview
**pytaglib** is a full-featured, easy-to-use, cross-platform audio metadata ("tag") library for [Python](http://www.python.org) (all versions supported). It uses the popular, fast and rock-solid [TagLib](http://taglib.github.io) C++ library internally; **pytaglib** is a very thin wrapper about TagLib (<150 lines of code), meaning that you immediately profit from the underlying library's speed and stability.

Features include [support of more than a dozen file formats](http://taglib.github.io), [arbitrary tag names](#arbitag), and [multiple values per tag](#multival).

## Usage Example

- Open a file and read its tags:
```python
>>> import taglib
>>> song = taglib.File("/path/to/my/file.mp3")
>>> song.tags
{'ARTIST': ['piman', 'jzig'], 'ALBUM': ['Quod Libet Test Data'], 'TITLE': ['Silence'], 'GENRE': ['Silence'], 'TRACKNUMBER': ['02/10'], 'DATE': ['2004']}
```
- Read some additional properties of the file:
```python
>>> song.length
239
>>> song.channels
2
```
- Change the file's tags:
```python
>>> song.tags["ALBUM"] = ["White Album"] # always use lists, even for single values
>>> del song.tags["DATE"]
```
- Multiple values per tag:<a name="multival"></a>
```python
>>> song.tags["GENRE"] = ["Vocal", "Classical"]
```
- Non-standard tags:<a name="arbitag"></a>
```python
>>> song.tags["PERFORMER:HARPSICHORD"] = ["Ton Koopman"] 
```
- Save your changes:
```python
>>> returnvalue = song.save()
>>> returnvalue
{}
```
The dictionary returned by `save` contains all tags that could not be saved (might happen if the specific format does not support e.g. multi-values).


**Note:** All strings in the tag dictionary are unicode strings (type `str` in Python 3 and `unicode` in Python 2). On the input side, however, the library is rather permissive and supports both byte- and unicode-strings. Internally, `pytaglib` converts
all strings to `UTF-8` before storing them in the files.

## Installation
The most recommended installation method is

        pip install pytaglib

subject to the following notes:
* Ensure that `pip` points to the correct Python version; you might need to use, e.g., `pip-3.5` if you want to install `pytaglib` for Python 3.5 and your system's default is Python 2.7.
* You may need administrator rights to install a package, i.e., `sudo pip install pytaglib` on Unix or running the command on a Admin console on windows
* Alternatively, install locally into your user home with `pip install --user pytaglib`.
* You need to have `taglib` installed with development headers (package `libtag1-dev` for debian-based linux, `brew install taglib` on OS X).
* If `taglib` is installed at a non-standard location, you can tell `pip` where to look for its include (`-I`) and library (`-L`) files:

        pip install --global-option=build_ext --global-option="-I/usr/local/include/" --global-option="-L/usr/local/lib" pytaglib

If the above does not work, continue reading for alternative methods of installation.

### Linux / Unix
#### Distribution-Specific Packages
* Debian- and Ubuntu-based linux flavors have binary packages for the Python 3 version, called `python3-taglib`. Unfortunatelly, they are heavily outdated, so you should use the above "pip" method whenever possible.
* For Arch users, there is a [package](https://aur.archlinux.org/packages/python-pytaglib/) in the user repository (AUR) which I try to keep up-to-date.
#### Manual Compilation
Alternatively, you can download / checkout the sources and compile manually:

        python setup.py build
        python setup.py test  # optional
        sudo python setup.py install

You can manually specify `taglib`'s include and library directories:

    python setup.py build --include-dirs /usr/local/include --library-dirs /usr/local/lib

**Note**: The `taglib` Python extension is built from the file `taglib.cpp` which in turn is
auto-generated by [Cython](http://www.cython.org) from `taglib.pyx`. To re-cythonize this file
instead of using the shipped `taglib.cpp`, invoke `setup.py` with the `--cython` option.

### Windows

Currently, the PyPI archive contains a binary version only for Python3.5/x64. For different combinations of Python version and architecture, you need to build yourself.

**Note**: The following procedure was tested for Python 3.5 on x64 only. Other python versions probably require some more work; see e.g. [this](https://blog.ionelmc.ro/2014/12/21/compiling-python-extensions-on-windows/) page.

1. Install [Microsoft Visual Studio 2015 Community Edition](https://www.visualstudio.com/downloads/download-visual-studio-vs). In the installation process, be sure to enable C/C++ support.
2. Download and build taglib:
    1. Download the current [taglib release](https://github.com/taglib/taglib/releases) and extract it somewhere   on your computer.
    2. Start the VS2015 x64 Native Tools Command Prompt. On Windows 8/10, it might not appear in your start menu, but you can find it here: `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio 2015\Visual Studio Tools\Windows Desktop Command Prompts`
    3. Navigate to the extracted taglib folder and type: `cmake -G "Visual Studio 14 2015 Win64" -DCMAKE_INSTALL_PREFIX=".\taglib-install"` to generate the Visual Studio project files.
    4. Type `msbuild INSTALL.vcxproj /p:Configuration=Release` which will "install" taglib into the `install` subdirectory.
3. Still in the VS2015 command prompt, navigate to the pytaglib directory.
4. Tell pytaglib where to find taglib: `set TAGLIB_HOME=C:\Path\To\Taglib\install`
5. Build pytaglib: `python setup.py build` and install: `python setup.py install`



## `pyprinttags`
This package also installs the small script `pyprinttags`. It takes one or more files as
command-line parameters and will display all known metadata of that files on the terminal.
If unsupported tags (a.k.a. non-textual information) are found, they can optionally be removed
from the file.

## `Contact`
For bug reports or feature requests, please use the
[issue tracker](https://github.com/supermihi/pytaglib/issues) on GitHub. For anything else, contact
me by [email](mailto:michaelhelmling@posteo.de).
