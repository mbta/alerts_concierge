[
  import_deps: [:phoenix],
  inputs: [
    "mix.exs",
    "apps/*/mix.exs",
    "apps/*/{config,lib,test}/**/*.{ex,exs}",
    "config/**/*.{ex,exs}",
    "rel/**/*.{ex,exs}",
    "scripts/**/*.{ex,exs}"
  ]
]
