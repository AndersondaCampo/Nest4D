unit App.Module;

interface

uses
  Nest4D;

type
  TAppModule = Class(TNestModule)
    constructor Create();
  End;

implementation

uses
  App.Service,
  App.Controller;

{ TAppModule }

constructor TAppModule.Create;
begin
  SetServices([TAppService]);
  SetControllers([TAppController]);
end;

end.
