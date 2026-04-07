---
name: haskell-docs
description: Look up Haskell package documentation, find where packages live, and search by function name or type signature. Use when you need haddock paths, library dirs, or to search docs with hoogle.
user-invocable: true
---

# Haskell Package Documentation

## Finding Package Paths with ghc-pkg

`ghc-pkg` queries the package database directly — instant, no filesystem scanning.

**Get the library directory**:
```
ghc-pkg field <package> library-dirs
```

**Get haddock interface file path** (for reading docs):
```
ghc-pkg field <package> haddock-interfaces
```

**Get `.hi` file directory**:
```
ghc-pkg field <package> import-dirs
```

**Inspect all fields for a package**:
```
ghc-pkg describe <package>
```

## Searching Documentation with Hoogle

**Search for a function by name**:
```
hoogle search "mapMaybe"
```

**Search by type signature**:
```
hoogle search "(a -> Bool) -> [a] -> [a]"
```

**Get detailed info including examples**:
```
hoogle search "traverse" --info
```

**Search within a specific module**:
```
hoogle search "module:Data.List take"
```

**Limit results**:
```
hoogle search "aeson" --count=10
```

**Common search patterns**:
- Find JSON parsing: `hoogle search "ByteString -> Maybe Value"`
- Find list functions: `hoogle search "module:Data.List"`
- Find lens operations: `hoogle search "Lens'"`
- Find typeclass instances: `hoogle search "Monad m =>"`
