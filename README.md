# Vyper (Prototype)

Vyper is an experimental programming language inspired by Python's syntax and
Go's performance and tooling.

This is a **minimal prototype** showing the first end-to-end flow:

-   Lexing
-   Parsing
-   Generating C code
-   Compiling to a native binary using `zig cc`

## 📦 Requirements

-   [Zig](https://ziglang.org/) **0.13.0** or newer

## 🚀 Usage

First, compile the `vyper` compiler itself:

```bash
zig build
```

This will produce a binary located at `zig-out/bin/vyper` which can be used to
compile one of the example `.vy` programs as follows:

```bash
./zig-out/bin/vyper build examples/hello.vy
```

This will compile the Vyper program to a single binary located in the
`out/hello` directory. To run this example, use the following:

```bash
./out/hello
```
