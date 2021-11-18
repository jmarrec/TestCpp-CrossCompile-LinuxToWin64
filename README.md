# TestCpp-CrossCompile-LinuxToWin64

[![C++ CI](https://github.com/jmarrec/TestCpp-CrossCompile-LinuxToWin64/actions/workflows/build.yml/badge.svg)](https://github.com/jmarrec/TestCpp-CrossCompile-LinuxToWin64/actions/workflows/build.yml)

A repo to test how to cross compile a dummy C++ project using Github Actions, mingw32, **and** conan.

The workflow file [build.yml](.github/workflows/build.yml) will show the steps necessary to make it work.

But the bottom line is that on Ubuntu (tested on ubuntu-20.4), you need to install the dependencies you need (conan and mingw-w64)

```bash
pip install conan
sudo apt-get install mingw-w64
```

Then build with the toolchain file [mingw-w64-x86_64.cmake](cmake/mingw-w64-x86_64.cmake) I created. This toolchain file also loads a specific conan cross-compiling profile: [conan_linux_to_win64](cmake/conan_linux_to_win64). You may need to tweak that conan profile to provide the specific version of the mingw-gcc you have (9.3 in my case).

```bash
mkdir build && cd build
cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=../cmake/mingw-w64-x86_64.cmake ../
ninja
```

If you want to test a few things locally while on ubuntu:

```bash
# Execute via wine (sudo apt install wine)
$ wine Products/main.exe
INFO: Hello World

# See the dlls it links to
$ objdump --private-headers Products/main.exe | /bin/grep "DLL Name:"
	DLL Name: KERNEL32.dll
	DLL Name: msvcrt.dll
	DLL Name: libtestlib.dll
```
