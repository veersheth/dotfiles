return {
  root_markers = { "Cargo.toml", "Cargo.lock" },
  settings = {
    ["rust-analyzer"] = {
      cargo = { allFeatures = true },
      checkOnSave = true,
      check = { command = "clippy" },
    },
  },
}
