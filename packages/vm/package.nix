{
  writeShellApplication,
  OVMF,
  python3,
  qemu_kvm,
}:

writeShellApplication {
  name = "vm";
  runtimeInputs = [
    qemu_kvm
    python3
  ];
  text = ''
    export VM_OVMF_FIRMWARE=${OVMF.firmware}
    export VM_OVMF_VARIABLES=${OVMF.variables}
    exec python ${./vm.py} "$@"
  '';
}
