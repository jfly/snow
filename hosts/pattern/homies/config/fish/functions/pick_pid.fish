function __pick_pid
    xprop _NET_WM_PID | sed 's/_NET_WM_PID(CARDINAL) = //'
end

function pick_pid
    commandline --insert -- (__pick_pid)
end
