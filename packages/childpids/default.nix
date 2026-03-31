{
  buildPythonApplication,
  hatchling,
  typer,
  psutil,
}:

buildPythonApplication {
  name = "childpids";
  pyproject = true;
  build-system = [ hatchling ];
  src = ./.;

  dependencies = [
    typer
    psutil
  ];
}
