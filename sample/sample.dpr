program sample;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  System.JSON,
  Horse,
  Nest4D in '..\src\Nest4D.pas',
  Nest4D.methods in '..\src\Nest4D.methods.pas',
  Nest4D.Types in '..\src\Nest4D.Types.pas',
  Nest4D.Attrs in '..\src\Nest4D.Attrs.pas',
  App.Module in 'App\App.Module.pas',
  App.Service in 'App\App.Service.pas',
  DB.Service in 'DB\DB.Service.pas',
  App.Controller in 'App\App.Controller.pas';

begin
  try
    Bootstrap(TAppModule);
    THorse.Port := 3030;
    THorse.Listen(
      procedure
      begin
        writeln('Server running');
        writeln('Press any key to stop...');
        Readln;
        THorse.StopListen;
      end);
  except
    on E: Exception do
      writeln(E.ClassName, ': ', E.Message);
  end;

end.
