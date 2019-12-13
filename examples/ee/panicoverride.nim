{.push stack_trace: off, profiler:off.}
proc debug_printMemHex*(offset: pointer, length: uint32) {.noreturn, cdecl, importc.}
proc rawoutput(s: string) = 
    debug_printMemHex(cstring(s), s.len.uint32)
proc panic(s: string) = rawoutput(s)
{.pop.}
