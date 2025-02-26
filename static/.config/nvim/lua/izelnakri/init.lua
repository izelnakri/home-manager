require("izelnakri.globals")
require("izelnakri.options")

require("izelnakri.utils")

require("izelnakri.commands")
require("izelnakri.keymaps")
require("izelnakri.autocmds")

require("izelnakri.lazy_init")

require("izelnakri.services")

-- TODO: add treesitter for .vcf and .ics filetypes
-- Read up on my vcard apple attributes. Read up on my vcard google contacts attributes
-- Read up on ics google calendar event attributes
-- Why taskwarrior? - json storage & easier sync, programmatic hooks, standardized cli and query interface, one shot command reports
-- Try to run web client of proton, then the bridge software can toggle notifications etc, gluon

-- Also run buffer-execute.lua/or nvim plugin that execute buffers, also check running tests onSave(and on neotest)
-- Also run lua debugger
-- Also run lua lsp
