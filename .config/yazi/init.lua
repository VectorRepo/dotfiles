-- Track directories visited inside yazi itself, not just `cd` in the shell,
-- so the zoxide directory history (bound to `z`) actually fills up from
-- normal browsing.
require("zoxide"):setup({ update_db = true })
