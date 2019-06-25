{.push stack_trace: off, profiler:off.}
proc revert(dataOffset: pointer; length: int32) {.noreturn, cdecl, importc.}
proc rawoutput(s: string) = 
    revert(cstring(s), s.len.int32)
proc panic(s: string) = rawoutput(s)
{.pop.}
