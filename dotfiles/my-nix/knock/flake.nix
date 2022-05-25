{
  inputs = {
    knock.url = "github:BentonEdmondson/knock";
    knock.inputs.rmdrm.url = "github:jfly/rmdrm/13d2a0bcc29240b348bc8b358e34dafcd8c738a1";
  };
  outputs = flakes: flakes.knock;
}
