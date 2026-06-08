--- Bootstrap loader. Single require line bridges init.lua to the CodeHub package.
--- Kept thin intentionally — all logic lives in packages.codehub.init for testability.

require("packages.codehub")
