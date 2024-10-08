{ ... }:

{
  # Populate a quickfix list (and keep it up to date with changes!) with all
  # diagnostics in a workspace.
  # This is basically a simplified (quickfix-only) version of
  # <https://github.com/onsails/diaglist.nvim>. This code also takes advantage
  # of quickfix list ids to ensure we always update the exact same list each
  # time.

  extraConfigLuaPre = ''
    snow_diag = {}
    do
      snow_diag.title = "Diagnostics"
      snow_diag._qf_id = nil

      snow_diag.replace_qf_list = function()
        local all_diags = vim.diagnostic.get()
        local qflist = vim.diagnostic.toqflist(all_diags)

        if snow_diag._qf_id then
          vim.fn.setqflist({}, 'r', {
            items = qflist,
            id = snow_diag._qf_id,
          })
        else
          vim.fn.setqflist({}, ' ', {
            items = qflist,
            title = snow_diag.title,
            id = snow_diag._qf_id,
          })

          -- Get the id of the newly created quickfix list.
          snow_diag._qf_id = vim.fn.getqflist({ id = 0 }).id
        end
      end

      vim.api.nvim_create_autocmd('DiagnosticChanged', {
        callback = snow_diag.replace_qf_list,
      })
    end
  '';
}
