{
  buildPythonApplication,
  hatchling,
  pexpect,
}:

buildPythonApplication {
  name = "unlock";
  pyproject = true;
  build-system = [ hatchling ];
  src = ./.;

  dependencies = [
    pexpect
  ];
}
