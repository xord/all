# Rucy

Ruby C++ Extension Helper Library. Reduces boilerplate when writing Ruby extensions in C++.

## ERB Code Generation

`src/*.cpp.erb` and `include/rucy/*.h.erb` are ERB templates expanded at build time.
`NPARAM_MAX = 12` auto-generates function bindings for 0–12 parameters.

## Macro API

Define Ruby methods from C++ using dedicated macros:
```cpp
RUCY_DEF0(method_name)
{
  // ...
}
RUCY_END
```

## Tools

- `bin/rucy2rdoc` — Converts C++ doc macros to RDoc format
