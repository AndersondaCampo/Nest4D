program sample;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  System.JSON,
  Nest4D in '..\src\Nest4D.pas',
  Nest4D.route in '..\src\Nest4D.route.pas',
  Nest4D.methods in '..\src\Nest4D.methods.pas',
  Nest4D.DI.service in '..\src\DI\Nest4D.DI.service.pas',
  Nest4D.DI.module in '..\src\DI\Nest4D.DI.module.pas';

type

  [Route('test')]
  TTestController = class
  private
  public
    [GET(':id')] { /test/10 }
    procedure getId([Param] id: Integer; [Response] res: TRes);

    [GET] { /test?name=Jhon }
    function getName([Query] name: String): String;

    [GET('arr')] { /test/arr }
    function getJsonArr: TJSONArray;

    [GET('number')] { /test/number }
    function getNumber: Integer;

    { TODO : Future inject dependencies }
    constructor Create({ [Inject] myDep: IMyDep });
    destructor Destroy(); override;
  end;

  { TTestController }

constructor TTestController.Create;
begin

end;

destructor TTestController.Destroy;
begin
  inherited;
end;

function TTestController.getName(name: String): String;
begin
  Result := '{"name": "' + name + '"}';
end;

procedure TTestController.getId([TParam] id: Integer; res: TRes);
begin
  res.Send('Your ID is ' + id.ToString);
end;

function TTestController.getJsonArr: TJSONArray;
var
  I: Integer;
begin
  Result := TJSONArray.Create;
  for I  := 0 to 999 do
  begin
    Result.AddElement(TJSONObject.Create(TJSONPair.Create('id', TJSONNumber.Create(I))));
  end;
end;

function TTestController.getNumber: Integer;
begin
  Result := 10;
end;

begin
  ReportMemoryLeaksOnShutdown := True;

  try
    TNest4D.RegisterController(TTestController);
    TNest4D.Bootstrap;
    TNest4D.Start(3030,
        procedure
      begin
        writeln('Server started');
      end);
  except
    on E: Exception do
      writeln(E.ClassName, ': ', E.Message);
  end;

end.
