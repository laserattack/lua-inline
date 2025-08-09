# LuaJIT Inline

A very simple small module that allows you to inline C code in LuaJIT code

## Deps

LuaJIT, GCC

## Example

```lua
local inline = require("inline")

inline[[
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

void my_signal_handler(int signum) {
    printf("Custom handler received signal: %d\n", signum);
    exit(1);
}

void setup_signal_handler() {
    signal(SIGINT, my_signal_handler);
}

int add_numbers(int a, int b) {
    return a + b;
}

void print_message(const char* msg) {
    printf("Message: %s\n", msg);
}
]]

print(add_numbers(1, 2)) --> 3
print_message("hello from C!") --> Message: hello from C!

setup_signal_handler()
print("press Ctrl+C to exit")
while true do end
```