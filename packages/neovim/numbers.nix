{
  extraConfigLua = ''
    if os.getenv("MOB_TIMER_ROOM") then
      vim.wo.number = true
    end
  '';
}
