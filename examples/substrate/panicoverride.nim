{.push stack_trace: off, profiler:off.}
proc ext_println*(offset: pointer, length: uint32) {.noreturn, cdecl, importc.}
proc rawoutput(s: string) = 
    ext_println(cstring(s), s.len.uint32)
proc panic(s: string) = rawoutput(s)
{.pop.}
