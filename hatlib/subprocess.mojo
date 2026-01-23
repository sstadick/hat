"""Implements the subprocess package.

Modified version of https://github.com/modular/modular/blob/65301d9c24fab2245dbec18f1d7a8de0e1e08590/mojo/stdlib/std/subprocess/subprocess.mojo#L85
"""


import sys._libc as libc
from sys import external_call
from sys._libc import FILE_ptr, pclose, popen
from sys.ffi import c_char
from sys.info import CompilationTarget

from memory import Span


# TODO: handle this but with the iterator now
struct CompletedProcess(Copyable, Movable):
    """Result of a subprocess execution."""

    var stdout: String
    var returncode: Int

    fn __init__(out self, stdout: String = "", returncode: Int = 0):
        self.stdout = stdout
        self.returncode = returncode

    fn check(self) raises:
        """Raises an error if the process exited with a non-zero status."""
        if self.returncode != 0:
            raise Error(
                "Command failed with exit code ",
                self.returncode,
                ": ",
                self.stdout,
            )


struct _POpenHandle[mimic_tty: Bool = False](Iterable):
    """Handle to an open file descriptor opened via popen."""

    alias IteratorType[
        iterable_mut: Bool, //, iterable_origin: Origin[iterable_mut]
    ]: Iterator = _LineIter[mimic_tty, iterable_origin]

    var _handle: FILE_ptr
    var _closed: Bool

    fn __init__(
        out self,
        var cmd: String,
        var mode: String = "r",
        capture_stderr_to_stdout: Bool = False,
    ) raises:
        if mode != "r" and mode != "w":
            raise Error("the mode specified `", mode, "` is not valid")

        var full_cmd = cmd
        if capture_stderr_to_stdout:
            full_cmd = cmd + " 2>&1"

        @parameter
        if mimic_tty:
            if CompilationTarget.is_macos():
                full_cmd = "script -q /dev/null " + full_cmd
            else:
                full_cmd = full_cmd.replace("'", "'\"'\"'")
                full_cmd = "script -qec '" + full_cmd + "' /dev/null"

        self._handle = popen(
            full_cmd.unsafe_cstr_ptr(),
            mode.unsafe_cstr_ptr(),
        )
        self._closed = False
        if not self._handle:
            raise Error("unable to execute the command `", cmd, "`")

    fn __del__(deinit self):
        """Closes the handle if not already closed."""
        if not self._closed:
            _ = pclose(self._handle)

    fn close(mut self) -> Int:
        """Closes the handle and returns the exit status."""
        self._closed = True
        var status = pclose(self._handle)
        # pclose returns the exit status in the same format as waitpid
        # Extract the actual exit code
        return Int(status >> 8)

    fn __iter__(ref self) -> Self.IteratorType[origin_of(self)]:
        return _LineIter[mimic_tty, origin_of(self)](Pointer(to=self))

    fn read_all(self) raises -> String:
        """Reads all the data from the handle."""
        var len: Int = 0
        var line = UnsafePointer[c_char, MutOrigin.external]()
        var res = String()
        while True:
            var read = external_call["getline", Int](
                Pointer(to=line), Pointer(to=len), self._handle
            )
            if read == -1:
                break
            # Explicitly allowing shenanigans here because we want to capture colored output
            res += StringSlice(
                unsafe_from_utf8=Span(ptr=line.bitcast[Byte](), length=read)
            )
        if line:
            libc.free(line.bitcast[NoneType]())
        return String(res.rstrip())


struct _LineIter[mut: Bool, //, mimic_tty: Bool, origin: Origin[mut]](Iterator):
    # TODO: with new iterator return a reference to the bytes, or just anything that doesn't copy
    alias Element = String

    var _len: Int
    var _line: UnsafePointer[c_char, MutOrigin.external]
    var _handle: Pointer[_POpenHandle[mimic_tty], origin]

    fn __init__(out self, handle: Pointer[_POpenHandle[mimic_tty], origin]):
        self._line = UnsafePointer[c_char, MutOrigin.external]()
        self._len = 0
        self._handle = handle
        self._try_getline()

    fn __del__(deinit self):
        libc.free(self._line.bitcast[NoneType]())
        # The _POpenHandle that gave us this handle should close that.
        # pclose(self._handle)

    fn __has_next__(read self) -> Bool:
        return self._len != -1

    fn _try_getline(mut self):
        var read = external_call["getline", Int](
            Pointer(to=self._line),
            Pointer(to=self._len),
            self._handle[]._handle,
        )
        if read == -1:
            self._len = -1
        else:
            self._len = read  # Store the actual bytes read

    fn __next__(mut self) -> Self.Element:
        # Current line data is in _line with length _len
        var ret = String(
            StringSlice(
                unsafe_from_utf8=Span(
                    ptr=self._line.bitcast[Byte](), length=self._len
                )
            )
        )

        # Try to read the next line for the next iteration
        self._try_getline()

        return ret^


fn run[
    mimic_tty: Bool = False
](
    cmd: String, capture_stderr_to_stdout: Bool = True
) raises -> CompletedProcess:
    """Runs the specified command and returns the result.

    Args:
        cmd: The command to execute.
        capture_stderr_to_stdout: If True, captures stderr along with stdout.

    Returns:
        A CompletedProcess with stdout and returncode.
    """
    var hdl = _POpenHandle[mimic_tty](
        cmd, capture_stderr_to_stdout=capture_stderr_to_stdout
    )
    var output = hdl.read_all()
    var code = hdl.close()
    return CompletedProcess(output, code)


# def main():
#     var handle = _POpenHandle[True](
#         "cat ./pixi.toml", capture_stderr_to_stdout=True
#     )
#     for ref line in handle:
#         print(line)
